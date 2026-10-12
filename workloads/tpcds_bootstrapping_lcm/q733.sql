SELECT
    cc.cc_country AS call_center_country,
    s.s_state AS store_state,
    d_cr.d_year AS return_year,
    COUNT(cr.cr_order_number) AS total_returns,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(CASE WHEN d_cc_closed.d_month_seq = d_cc_open.d_month_seq THEN 1 ELSE 0 END) AS same_month_open_close,
    AVG(CASE WHEN d_store.d_year = d_cr.d_year THEN 1.0 ELSE 0.0 END) AS store_closed_same_year_ratio,
    MAX(s.s_floor_space) AS max_store_floor_space,
    MIN(wp.wp_image_count) AS min_web_page_image_count,
    COUNT(DISTINCT wp.wp_type) AS distinct_web_page_types
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN web_page wp
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_cr.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
  AND wp.wp_type IS NOT NULL
GROUP BY
    cc.cc_country,
    s.s_state,
    d_cr.d_year
HAVING COUNT(cr.cr_order_number) > 10
ORDER BY sum_return_amount DESC
LIMIT 100
