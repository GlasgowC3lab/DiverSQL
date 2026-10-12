SELECT
    cc.cc_name AS call_center_name,
    cc.cc_manager AS call_center_manager,
    cc.cc_tax_percentage AS call_center_tax_pct,
    cc.cc_employees AS call_center_employees,
    cc.cc_sq_ft AS call_center_sq_ft,
    s.s_store_name AS store_name,
    s.s_manager AS store_manager,
    s.s_tax_percentage AS store_tax_pct,
    s.s_number_employees AS store_employees,
    s.s_floor_space AS store_floor_space,
    cp.cp_catalog_page_id AS catalog_page_id,
    cp.cp_type AS catalog_type,
    cp.cp_description AS catalog_description,
    d_cc_open.d_date AS call_center_open_date,
    d_cc_closed.d_date AS call_center_closed_date,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_end.d_date AS catalog_end_date,
    d_store_closed.d_date AS store_closed_date,
    date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS call_center_operational_days,
    date_diff('day', d_cp_start.d_date, d_cp_end.d_date) AS catalog_page_active_days,
    (cc.cc_tax_percentage + s.s_tax_percentage) / 2 AS combined_tax_rate,
    (cc.cc_sq_ft + s.s_floor_space) AS total_sq_ft,
    (cc.cc_employees + s.s_number_employees) AS total_employees,
    (cc.cc_sq_ft * cc.cc_tax_percentage) + (s.s_floor_space * s.s_tax_percentage) AS weighted_tax_sqft,
    ROW_NUMBER() OVER (ORDER BY (cc.cc_sq_ft + s.s_floor_space) DESC) AS rank_by_total_sqft
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
CROSS JOIN catalog_page cp
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_cc_open.d_date <= d_cp_end.d_date
  AND d_cc_closed.d_date >= d_cp_start.d_date
  AND d_store_closed.d_date BETWEEN d_cc_open.d_date AND d_cc_closed.d_date
  AND d_store_closed.d_date BETWEEN d_cp_start.d_date AND d_cp_end.d_date
ORDER BY total_sq_ft DESC
LIMIT 100
