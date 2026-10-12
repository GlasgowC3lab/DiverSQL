WITH cr AS (
    SELECT
        cr_refunded_customer_sk AS cust_sk,
        cr_refunded_hdemo_sk AS hdemo_sk,
        cr_refunded_cash AS refunded_cash,
        cr_net_loss AS net_loss,
        cr_return_amount AS return_amount,
        cr_returned_date_sk AS date_sk
    FROM catalog_returns
    WHERE cr_refunded_cash > 0
),
sr AS (
    SELECT
        sr_customer_sk AS cust_sk,
        sr_hdemo_sk AS hdemo_sk,
        sr_refunded_cash AS refunded_cash,
        sr_net_loss AS net_loss,
        sr_return_amt AS return_amount,
        sr_returned_date_sk AS date_sk
    FROM store_returns
    WHERE sr_refunded_cash > 0
),
wr AS (
    SELECT
        wr_refunded_customer_sk AS cust_sk,
        wr_refunded_hdemo_sk AS hdemo_sk,
        wr_refunded_cash AS refunded_cash,
        wr_net_loss AS net_loss,
        wr_return_amt AS return_amount,
        wr_returned_date_sk AS date_sk
    FROM web_returns
    WHERE wr_refunded_cash > 0
),
combined AS (
    SELECT * FROM cr
    UNION ALL
    SELECT * FROM sr
    UNION ALL
    SELECT * FROM wr
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT combined.cust_sk) AS distinct_customers,
    SUM(combined.refunded_cash) AS total_refunded_cash,
    SUM(combined.net_loss) AS total_net_loss,
    AVG(combined.return_amount) AS avg_return_amount
FROM combined
JOIN household_demographics hd ON combined.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer c ON combined.cust_sk = c.c_customer_sk
WHERE combined.date_sk BETWEEN 2450900 AND 2451100
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY total_net_loss DESC
LIMIT 20
