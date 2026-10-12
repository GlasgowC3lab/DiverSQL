SELECT
    cc.cc_company_name,
    cc.cc_division_name,
    cc.cc_tax_percentage,
    cc.cc_state,
    cc.cc_city,
    dd_cc_closed.d_year AS closed_year,
    dd_cc_closed.d_month_seq AS closed_month,
    dd_cc_open.d_year AS open_year,
    dd_cc_open.d_month_seq AS open_month,
    cp.cp_type,
    cp.cp_catalog_number,
    cp.cp_description,
    dd_cp_start.d_year AS cp_start_year,
    dd_cp_start.d_month_seq AS cp_start_month,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    wp.wp_autogen_flag,
    dd_wp_access.d_year AS wp_access_year,
    dd_wp_access.d_month_seq AS wp_access_month,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_number_employees,
    dd_store_closed.d_year AS store_closed_year,
    dd_store_closed.d_month_seq AS store_closed_month,
    CASE WHEN dd_wp_access.d_year = dd_cc_closed.d_year THEN 1 ELSE 0 END AS access_same_year_flag,
    wp.wp_image_count * 1.0 / nullif(wp.wp_link_count, 0) AS images_per_link,
    SUM(wp.wp_image_count) OVER (PARTITION BY cc.cc_division) AS total_images_by_division,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_company_name ORDER BY dd_cc_closed.d_date_sk DESC) AS rn,
    CASE
        WHEN dd_cc_closed.d_quarter_seq = dd_store_closed.d_quarter_seq THEN 'SameQuarter'
        ELSE 'DiffQuarter'
    END AS quarter_match
FROM call_center cc
JOIN date_dim dd_cc_closed ON cc.cc_closed_date_sk = dd_cc_closed.d_date_sk
JOIN date_dim dd_cc_open ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = dd_cc_closed.d_date_sk
JOIN date_dim dd_cp_start ON cp.cp_start_date_sk = dd_cp_start.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = dd_cp_start.d_date_sk
JOIN date_dim dd_wp_access ON wp.wp_access_date_sk = dd_wp_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = dd_cc_closed.d_date_sk
JOIN date_dim dd_store_closed ON s.s_closed_date_sk = dd_store_closed.d_date_sk
WHERE cc.cc_tax_percentage > 5.00
  AND s.s_state = 'CA'
  AND dd_cc_closed.d_year = 2022
  AND wp.wp_autogen_flag = 'Y'
ORDER BY dd_cc_closed.d_year DESC, cc.cc_company_name
LIMIT 100
