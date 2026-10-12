SELECT
    s.s_state,
    cp.cp_type,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month,
    d_end.d_year AS end_year,
    d_end.d_month_seq AS end_month,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS num_catalog_pages,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages,
    SUM(wp.wp_max_ad_count) AS total_max_ads,
    AVG(wp.wp_char_count) AS avg_char_count,
    AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_page_duration_days,
    SUM(CASE WHEN s.s_market_desc = 'Urban' THEN 1 ELSE 0 END) AS urban_store_count
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
   AND wp.wp_access_date_sk = d_end.d_date_sk
WHERE d_start.d_year >= 2020
  AND d_end.d_year <= 2025
GROUP BY
    s.s_state,
    cp.cp_type,
    d_start.d_year,
    d_start.d_month_seq,
    d_end.d_year,
    d_end.d_month_seq
HAVING COUNT(DISTINCT cp.cp_catalog_page_id) > 5
ORDER BY s.s_state, cp.cp_type, start_year, start_month
LIMIT 100
