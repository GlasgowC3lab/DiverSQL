WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2001 AND 2003
    GROUP BY d.d_year, d.d_quarter_seq, cd.cd_gender, cd.cd_marital_status
),

returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2001 AND 2003
      AND r.r_reason_desc LIKE '%Damaged%'
    GROUP BY d.d_year, d.d_quarter_seq, cd.cd_gender, cd.cd_marital_status
)

SELECT
    s.d_year,
    s.d_quarter_seq,
    s.cd_gender,
    s.cd_marital_status,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_profit - COALESCE(r.total_return_amount, 0) AS net_profit_after_returns,
    s.num_transactions,
    COALESCE(r.num_returns, 0) AS num_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_quarter_seq = r.d_quarter_seq
   AND s.cd_gender = r.cd_gender
   AND s.cd_marital_status = r.cd_marital_status
ORDER BY s.d_year, s.d_quarter_seq, s.cd_gender, s.cd_marital_status
