SELECT
    s.s_state,
    cc.cc_market_manager,
    cp.cp_type,
    wp.wp_type,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    d_cp_start.d_year AS cp_start_year,
    d_wp_access.d_year AS wp_access_year,
    CASE
        WHEN d_cc_closed.d_month_seq <= 6 THEN 'H1'
        ELSE 'H2'
    END AS cc_closed_half_year,
    CASE
        WHEN d_cc_closed.d_year = d_cc_open.d_year THEN 'Same Year Closed/Open'
        ELSE 'Different Years Closed/Open'
    END AS cc_closed_open_year_relation,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
    COUNT(DISTINCT s.s_store_sk) AS num_stores,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_catalog_pages,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(cc.cc_tax_percentage - s.s_tax_percentage) AS avg_tax_diff,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    ROUND(SUM(wp.wp_image_count) * 1.0 / NULLIF(SUM(wp.wp_link_count), 0), 2) AS image_to_link_ratio,
    SUM(cp.cp_catalog_number) AS total_catalog_numbers,
    AVG(date_diff('day', d_cc_open.d_date, d_cc_closed.d_date)) AS avg_cc_days_open,
    AVG(date_diff('day', d_cp_start.d_date, d_wp_access.d_date)) AS avg_wp_days_active,
    AVG(date_diff('day', d_cc_open.d_date, d_cp_start.d_date)) AS avg_days_open_to_cp_start,
    ROUND(SUM(cc.cc_employees) * 1.0 / NULLIF(SUM(s.s_number_employees), 0), 2) AS cc_to_store_employee_ratio
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_state,
    cc.cc_market_manager,
    cp.cp_type,
    wp.wp_type,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    d_cp_start.d_year,
    d_wp_access.d_year,
    CASE
        WHEN d_cc_closed.d_month_seq <= 6 THEN 'H1'
        ELSE 'H2'
    END,
    CASE
        WHEN d_cc_closed.d_year = d_cc_open.d_year THEN 'Same Year Closed/Open'
        ELSE 'Different Years Closed/Open'
    END
LIMIT 100
