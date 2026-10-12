SELECT
    cp.cp_department,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month_seq,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    MAX(d_end.d_date) AS latest_catalog_end_date,
    MIN(d_promo_end.d_date) AS earliest_promo_end_date
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_end.d_date_sk
WHERE d_start.d_year = 2022
GROUP BY cp.cp_department, d_start.d_year, d_start.d_month_seq
HAVING SUM(p.p_cost) > 5000
ORDER BY total_promo_cost DESC
LIMIT 100
