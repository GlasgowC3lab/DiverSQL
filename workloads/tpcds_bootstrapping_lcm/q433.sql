SELECT
    d_closed.d_year,
    d_closed.d_month_seq,
    CASE
        WHEN d_closed.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_closed.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_closed.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    cp.cp_type,
    cc.cc_market_manager,
    s.s_market_manager,
    COUNT(*) AS total_rows,
    SUM(cc.cc_tax_percentage) AS sum_cc_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    SUM(cc.cc_employees) AS sum_cc_employees,
    SUM(s.s_number_employees) AS sum_store_employees,
    AVG(CAST(s.s_floor_space AS double) / NULLIF(s.s_number_employees, 0)) AS avg_floor_space_per_employee,
    COUNT(DISTINCT cc.cc_call_center_id) AS distinct_cc_ids,
    COUNT(DISTINCT s.s_store_id) AS distinct_store_ids
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_closed.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
GROUP BY
    d_closed.d_year,
    d_closed.d_month_seq,
    CASE
        WHEN d_closed.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_closed.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_closed.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    cp.cp_type,
    cc.cc_market_manager,
    s.s_market_manager
ORDER BY total_rows DESC
LIMIT 100
