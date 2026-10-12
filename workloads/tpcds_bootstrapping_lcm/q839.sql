SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    AVG(wp.wp_image_count) AS avg_image_count,
    MAX(wp.wp_link_count) AS max_link_count,
    MIN(wp.wp_char_count) AS min_char_count,
    COUNT(*) FILTER (WHERE d_cc_closed.d_date_sk IS NOT NULL) AS closed_date_rows,
    COUNT(*) FILTER (WHERE d_cc_open.d_date_sk IS NOT NULL) AS open_date_rows
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
    AND wp.wp_access_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2022
  AND cc.cc_country = 'United States'
  AND s.s_country = 'United States'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date
ORDER BY total_return_amount DESC
LIMIT 100
