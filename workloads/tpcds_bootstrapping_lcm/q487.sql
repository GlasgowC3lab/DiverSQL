SELECT
    cp.cp_department,
    s.s_state,
    d_start.d_year,
    d_start.d_moy,
    CASE
        WHEN d_start.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END AS month_parity,
    COUNT(cp.cp_catalog_page_id) AS catalog_page_cnt,
    COUNT(DISTINCT s.s_store_id) AS distinct_store_cnt,
    SUM(wp.wp_image_count) AS total_images,
    AVG(wp.wp_link_count) AS avg_links,
    SUM(CASE WHEN wp.wp_type = 'advertisement' THEN 1 ELSE 0 END) AS ad_page_cnt,
    SUM(wp.wp_char_count) AS total_characters,
    MAX(d_end.d_date) AS latest_end_date,
    MIN(d_start.d_date) AS earliest_start_date,
    SUM(wp.wp_image_count) / NULLIF(SUM(wp.wp_link_count), 0) AS image_to_link_ratio,
    AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_days_start_to_end,
    AVG(date_diff('day', d_end.d_date, d_access.d_date)) AS avg_days_end_to_access
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_end.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_start.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
GROUP BY
    cp.cp_department,
    s.s_state,
    d_start.d_year,
    d_start.d_moy,
    CASE
        WHEN d_start.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END
HAVING COUNT(cp.cp_catalog_page_id) > 5
ORDER BY catalog_page_cnt DESC
LIMIT 100
