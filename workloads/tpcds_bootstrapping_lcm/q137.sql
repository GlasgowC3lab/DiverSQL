SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    cc.cc_state AS call_center_state,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    p.p_promo_name,
    p.p_discount_active,
    wp.wp_url,
    wp.wp_type,
    d_closed.d_date AS closed_date,
    d_open.d_date AS open_date,
    d_promo_end.d_date AS promo_end_date,
    d_wp_access.d_date AS wp_access_date,
    date_diff('day', d_open.d_date, d_closed.d_date) AS call_center_open_days,
    date_diff('day', d_closed.d_date, d_promo_end.d_date) AS promo_duration_days,
    date_diff('day', d_closed.d_date, d_wp_access.d_date) AS web_page_access_delay,
    (cc.cc_employees + s.s_number_employees) AS total_employees,
    (cc.cc_sq_ft + s.s_floor_space) AS total_area_sq_ft,
    (cc.cc_tax_percentage + s.s_tax_percentage) / 2.0 AS avg_tax_percentage,
    p.p_cost,
    p.p_response_target,
    wp.wp_image_count,
    wp.wp_link_count,
    wp.wp_char_count
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_closed.d_date_sk
LEFT JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
ORDER BY total_area_sq_ft DESC
LIMIT 100
