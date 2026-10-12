SELECT
    dr_return.d_year AS return_year,
    dr_return.d_month_seq AS return_month,
    s.s_state AS store_state,
    c_refunded.c_birth_month AS birth_month,
    wp.wp_type AS web_page_type,
    ((c_refunded.c_birth_month - 1) / 3) + 1 AS birth_quarter,
    CASE WHEN s.s_gmt_offset > 0 THEN 'Eastern' ELSE 'Western' END AS region,
    COUNT(DISTINCT cr.cr_order_number) AS order_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    SUM(cr.cr_store_credit) AS total_store_credit,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_page_cnt
FROM catalog_returns cr
JOIN date_dim dr_return
    ON cr.cr_returned_date_sk = dr_return.d_date_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = dr_return.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c_refunded.c_customer_sk
JOIN date_dim dr_wp_creation
    ON wp.wp_creation_date_sk = dr_wp_creation.d_date_sk
JOIN date_dim dr_wp_access
    ON wp.wp_access_date_sk = dr_wp_access.d_date_sk
WHERE dr_return.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
GROUP BY
    dr_return.d_year,
    dr_return.d_month_seq,
    s.s_state,
    c_refunded.c_birth_month,
    wp.wp_type,
    ((c_refunded.c_birth_month - 1) / 3) + 1,
    CASE WHEN s.s_gmt_offset > 0 THEN 'Eastern' ELSE 'Western' END
HAVING SUM(cr.cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
