SELECT
    cp.cp_department,
    cp.cp_type,
    d_start.d_year AS start_year,
    CASE WHEN d_start.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_page_cnt,
    SUM(cp.cp_catalog_number) AS total_catalog_numbers,
    AVG(cp.cp_catalog_page_number) AS avg_catalog_page_number,
    AVG(DATE_DIFF('day', d_start.d_date, d_end.d_date)) AS avg_catalog_duration_days,
    COUNT(DISTINCT s.s_store_id) AS closed_store_cnt,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    SUM(s.s_number_employees) AS total_store_employees,
    AVG(s.s_gmt_offset) AS avg_store_gmt_offset,
    COUNT(DISTINCT ws.web_site_id) AS opened_web_site_cnt,
    AVG(ws.web_gmt_offset) AS avg_web_gmt_offset,
    AVG(ws.web_tax_percentage) AS avg_web_tax_percentage,
    AVG(DATE_DIFF('day', d_start.d_date, d_web_close.d_date)) AS avg_web_site_duration_days
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_start.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
GROUP BY
    cp.cp_department,
    cp.cp_type,
    d_start.d_year,
    CASE WHEN d_start.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END
ORDER BY
    cp.cp_department,
    start_year,
    half_year
