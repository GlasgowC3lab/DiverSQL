WITH customer_returns AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(*) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_fee) AS total_fee,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        MIN(sr.sr_returned_date_sk) AS first_return_date_sk,
        MAX(sr.sr_returned_date_sk) AS last_return_date_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 200
    GROUP BY sr.sr_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_salutation,
    c.c_birth_month,
    cr.num_returns,
    cr.total_return_amt,
    cr.total_net_loss,
    cr.avg_return_qty,
    cr.total_fee,
    cr.total_return_amt_inc_tax,
    (cr.total_net_loss / NULLIF(cr.total_return_amt, 0)) AS loss_to_return_ratio,
    DENSE_RANK() OVER (ORDER BY cr.total_return_amt DESC) AS return_amount_rank
FROM customer_returns cr
JOIN customer c
    ON cr.sr_customer_sk = c.c_customer_sk
WHERE c.c_salutation IN ('Mr.', 'Dr.')
  AND c.c_birth_month = 12
  AND c.c_first_shipto_date_sk IN (2450851, 2452197, 2449041)
ORDER BY cr.total_return_amt DESC
LIMIT 100
