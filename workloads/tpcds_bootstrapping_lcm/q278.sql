SELECT
    s.s_city,
    s.s_state,
    cp.cp_type,
    d_start.d_year AS start_year,
    d_start.d_moy AS start_month,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_pages,
    AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_catalog_duration_days,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages,
    AVG(wp.wp_image_count) AS avg_images_per_page,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    SUM(CASE WHEN d_start.d_moy = 12 THEN 1 ELSE 0 END) AS dec_start_pages,
    AVG(date_diff('day', d_start.d_date, d_wp_access.d_date)) AS avg_web_to_access_delay_days,
    (COUNT(DISTINCT wp.wp_web_page_id) * 1.0) / NULLIF(COUNT(DISTINCT cp.cp_catalog_page_id), 0) AS web_to_catalog_ratio
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_start.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_city,
    s.s_state,
    cp.cp_type,
    d_start.d_year,
    d_start.d_moy
HAVING COUNT(DISTINCT cp.cp_catalog_page_id) > 0
ORDER BY catalog_pages DESC
LIMIT 100
