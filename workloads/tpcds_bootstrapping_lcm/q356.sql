SELECT
    d_cc_open.d_year AS open_year,
    d_cc_closed.d_year AS close_year,
    d_cc_open.d_quarter_name AS open_quarter,
    cc.cc_state AS cc_state,
    cc.cc_country AS cc_country,
    s.s_state AS store_state,
    ws.web_state AS website_state,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
    COUNT(DISTINCT s.s_store_sk) AS num_stores,
    COUNT(DISTINCT ws.web_site_sk) AS num_web_sites,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    SUM(cc.cc_sq_ft) AS total_cc_sqft,
    SUM(s.s_floor_space) AS total_store_floor_space,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(ws.web_tax_percentage) AS avg_web_tax_pct,
    SUM(CASE WHEN s.s_state = cc.cc_state THEN 1 ELSE 0 END) AS stores_same_state_as_cc,
    SUM(CASE WHEN ws.web_state = cc.cc_state THEN 1 ELSE 0 END) AS websites_same_state_as_cc,
    SUM(CASE WHEN d_cc_closed.d_year > d_cc_open.d_year THEN d_cc_closed.d_year - d_cc_open.d_year ELSE 0 END) AS total_years_opened,
    AVG(CASE WHEN d_cc_closed.d_year > d_cc_open.d_year THEN d_cc_closed.d_year - d_cc_open.d_year END) AS avg_years_opened,
    (SUM(s.s_floor_space) / NULLIF(SUM(cc.cc_sq_ft), 0)) AS store_to_cc_floor_space_ratio,
    (AVG(cc.cc_tax_percentage) - AVG(s.s_tax_percentage)) AS tax_pct_diff_cc_store
FROM call_center cc
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_open.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_cc_open.d_date_sk
   AND ws.web_close_date_sk = d_cc_closed.d_date_sk
WHERE d_cc_open.d_year >= 2010
GROUP BY
    d_cc_open.d_year,
    d_cc_closed.d_year,
    d_cc_open.d_quarter_name,
    cc.cc_state,
    cc.cc_country,
    s.s_state,
    ws.web_state
HAVING COUNT(DISTINCT cc.cc_call_center_sk) > 1
ORDER BY open_year, close_year, cc_state
