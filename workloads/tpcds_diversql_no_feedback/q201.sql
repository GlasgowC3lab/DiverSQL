WITH cr_ships AS (
    SELECT
        cr.cr_refunded_customer_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sm.sm_carrier,
        sm.sm_type
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 0
)
SELECT
    cust.c_customer_id,
    CONCAT(cust.c_first_name, ' ', cust.c_last_name) AS full_name,
    REGEXP_EXTRACT(cust.c_email_address, '^([^@]+)') AS email_user,
    COUNT(wr.wr_order_number) AS web_return_count,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
    SUM(crs.cr_return_amount) AS total_catalog_return_amount,
    MAX(crs.sm_carrier) AS carrier_used
FROM customer cust
LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = cust.c_customer_sk
LEFT JOIN cr_ships crs ON crs.cr_refunded_customer_sk = cust.c_customer_sk
WHERE
    REGEXP_LIKE(cust.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND cust.c_last_name LIKE 'S%'
    AND cust.c_customer_sk NOT IN (
        SELECT cr_refunded_customer_sk FROM catalog_returns WHERE cr_return_amount > 500
    )
GROUP BY
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    cust.c_email_address
ORDER BY total_web_return_amount DESC
LIMIT 100
