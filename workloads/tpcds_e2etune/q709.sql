WITH sales_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_education_status,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_txn_cnt
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
      AND ss.ss_net_paid > 0
      AND hd.hd_vehicle_count >= 2
    GROUP BY cd.cd_demo_sk, cd.cd_education_status, cd.cd_gender, cd.cd_marital_status
),
returns_agg AS (
    SELECT
        cd.cd_demo_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_txn_cnt
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
      AND wr.wr_return_amt > 0
    GROUP BY cd.cd_demo_sk
)
SELECT
    s.cd_education_status,
    s.cd_gender,
    s.cd_marital_status,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_contribution,
    RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.cd_demo_sk = r.cd_demo_sk
ORDER BY net_contribution DESC
LIMIT 50
