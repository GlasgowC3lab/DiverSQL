SELECT
    s.s_state,
    cc.cc_manager,
    d.d_year,
    cp.cp_type,
    COUNT(DISTINCT s.s_store_sk) AS store_count,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_count,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    SUM(cp.cp_catalog_page_number) AS total_catalog_pages,
    MAX(d.d_month_seq) AS max_month_seq,
    SUM(CASE WHEN d.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_day_rows,
    MIN(d.d_date) AS earliest_date,
    MAX(d.d_date) AS latest_date
FROM store s
JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
    AND s.s_state IS NOT NULL
    AND cc.cc_manager IS NOT NULL
GROUP BY s.s_state, cc.cc_manager, d.d_year, cp.cp_type
HAVING COUNT(*) > 10
ORDER BY total_floor_space DESC
LIMIT 100
