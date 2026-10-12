SELECT
    CASE
        WHEN d_closed.d_year < 2010 THEN 'Pre-2010'
        ELSE '2010+'
    END AS period,
    cc.cc_state,
    s.s_state,
    cp.cp_type,
    wp.wp_type,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_centers,
    SUM(cc.cc_tax_percentage) AS sum_tax_pct,
    AVG(cc.cc_employees) AS avg_cc_employees,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(wp.wp_char_count) AS total_char_count,
    MAX(d_closed.d_date) AS max_closed_date,
    MIN(d_open.d_date) AS min_open_date
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_closed.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_closed.d_year BETWEEN 2000 AND 2022
  AND cc.cc_tax_percentage > 0
GROUP BY
    CASE
        WHEN d_closed.d_year < 2010 THEN 'Pre-2010'
        ELSE '2010+'
    END,
    cc.cc_state,
    s.s_state,
    cp.cp_type,
    wp.wp_type
HAVING COUNT(*) > 10
ORDER BY total_rows DESC
LIMIT 100
