WITH agg AS (
    SELECT
        rd.cd_gender AS returning_gender,
        rd.cd_marital_status AS returning_marital_status,
        fd.cd_gender AS refunded_gender,
        fd.cd_marital_status AS refunded_marital_status,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_fee) AS total_fee
    FROM web_returns wr
    JOIN customer_demographics rd
        ON wr.wr_returning_cdemo_sk = rd.cd_demo_sk
    JOIN customer_demographics fd
        ON wr.wr_refunded_cdemo_sk = fd.cd_demo_sk
    WHERE rd.cd_dep_employed_count >= 1
      AND fd.cd_dep_employed_count >= 1
      AND rd.cd_marital_status = 'M'
      AND fd.cd_marital_status = 'M'
      AND wr.wr_return_quantity > 0
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY
        rd.cd_gender,
        rd.cd_marital_status,
        fd.cd_gender,
        fd.cd_marital_status
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    returning_gender,
    returning_marital_status,
    refunded_gender,
    refunded_marital_status,
    total_returns,
    total_return_amount,
    total_return_amount_inc_tax,
    avg_net_loss,
    total_fee,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY return_amount_rank
LIMIT 100
