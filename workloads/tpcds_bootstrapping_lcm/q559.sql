SELECT
    cp.cp_department,
    s.s_state,
    ws.web_city,
    d_start.d_year AS start_year,
    CASE WHEN cp.cp_department = 'Electronics' THEN 'Tech' ELSE 'Other' END AS department_category,
    (d_end.d_year - d_start.d_year) AS catalog_duration_years,
    SUM(p.p_cost * p.p_response_target) AS total_expected_spend,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS num_catalog_pages,
    COUNT(DISTINCT s.s_store_id) AS num_stores_closed,
    COUNT(DISTINCT ws.web_site_id) AS num_web_sites_open,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    MAX(d_end.d_date) AS latest_catalog_end_date
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_start.d_date_sk
    AND p.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_start.d_date_sk
    AND ws.web_close_date_sk = d_end.d_date_sk
WHERE cp.cp_type = 'Seasonal'
    AND p.p_discount_active = 'Y'
GROUP BY
    cp.cp_department,
    s.s_state,
    ws.web_city,
    d_start.d_year,
    CASE WHEN cp.cp_department = 'Electronics' THEN 'Tech' ELSE 'Other' END,
    (d_end.d_year - d_start.d_year)
HAVING SUM(p.p_cost) > 5000
ORDER BY total_expected_spend DESC
LIMIT 100
