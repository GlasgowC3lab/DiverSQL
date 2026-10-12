SELECT
    d_cc_closed.d_year AS year,
    d_cc_closed.d_quarter_seq AS quarter,
    SUM(cc.cc_employees) AS total_call_center_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    SUM(cc.cc_sq_ft) AS total_call_center_sq_ft,
    SUM(s.s_floor_space) AS total_store_floor_space,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages,
    SUM(cp.cp_catalog_page_number) AS total_catalog_page_numbers,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    SUM(wp.wp_char_count) AS total_char_count,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    SUM(CASE WHEN cc.cc_employees > 500 THEN wp.wp_image_count ELSE 0 END) AS large_cc_image_count,
    SUM(CASE WHEN cc.cc_employees <= 500 THEN wp.wp_image_count ELSE 0 END) AS small_cc_image_count,
    (SUM(wp.wp_image_count) / NULLIF(SUM(wp.wp_link_count), 0)) AS image_to_link_ratio
FROM
    call_center cc
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    d_cc_closed.d_year,
    d_cc_closed.d_quarter_seq
ORDER BY
    d_cc_closed.d_year,
    d_cc_closed.d_quarter_seq
LIMIT 100
