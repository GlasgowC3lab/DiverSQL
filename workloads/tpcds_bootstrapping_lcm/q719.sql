SELECT
    d_cc_open.d_year AS cc_open_year,
    d_cc_open.d_current_month AS cc_open_month,
    d_cc_close.d_year AS cc_close_year,
    d_cc_close.d_current_month AS cc_close_month,
    cc.cc_state,
    s.s_state,
    ws.web_state,
    CASE WHEN cc.cc_tax_percentage > 5 THEN 'HIGH' ELSE 'LOW' END AS cc_tax_category,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HIGH' ELSE 'LOW' END AS store_tax_category,
    CASE WHEN ws.web_tax_percentage > 5 THEN 'HIGH' ELSE 'LOW' END AS web_tax_category,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
    COUNT(DISTINCT s.s_store_sk) AS num_stores,
    COUNT(DISTINCT ws.web_site_sk) AS num_web_sites,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    SUM(cc.cc_sq_ft) AS total_cc_sq_ft,
    SUM(s.s_floor_space) AS total_store_floor_space,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    AVG(ws.web_tax_percentage) AS avg_web_tax,
    (d_cc_close.d_year - d_cc_open.d_year) AS cc_years_active,
    (d_ws_close.d_year - d_cc_open.d_year) AS years_between_cc_open_and_ws_close
FROM call_center cc
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_close
    ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_close.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_cc_open.d_year >= 2015
GROUP BY
    d_cc_open.d_year,
    d_cc_open.d_current_month,
    d_cc_close.d_year,
    d_cc_close.d_current_month,
    cc.cc_state,
    s.s_state,
    ws.web_state,
    CASE WHEN cc.cc_tax_percentage > 5 THEN 'HIGH' ELSE 'LOW' END,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HIGH' ELSE 'LOW' END,
    CASE WHEN ws.web_tax_percentage > 5 THEN 'HIGH' ELSE 'LOW' END,
    d_ws_close.d_year
