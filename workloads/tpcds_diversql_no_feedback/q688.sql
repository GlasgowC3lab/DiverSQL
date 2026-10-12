WITH avg_return AS (
    SELECT avg(cr_return_amount) AS avg_amt
    FROM catalog_returns
)
SELECT
    sm1.sm_type,
    r1.r_reason_desc,
    c_refunded.c_birth_month,
    COUNT(*) AS return_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_quantity
FROM catalog_returns cr
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN ship_mode sm1
    ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN reason r1
    ON cr.cr_reason_sk = r1.r_reason_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c_refunded.c_customer_sk
JOIN ship_mode sm2
    ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN reason r2
    ON cr.cr_reason_sk = r2.r_reason_sk
JOIN customer c_web
    ON wp.wp_customer_sk = c_web.c_customer_sk
CROSS JOIN (SELECT 1 AS dummy) cross_tbl
WHERE cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
GROUP BY sm1.sm_type, r1.r_reason_desc, c_refunded.c_birth_month
ORDER BY total_return_amount DESC
LIMIT 100
