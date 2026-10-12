SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    closed_dim.d_year AS closed_year,
    closed_dim.d_quarter_name AS closed_quarter,
    COUNT(DISTINCT wp.wp_web_page_id) AS total_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    SUM(wp.wp_char_count) AS total_char_count,
    AVG(wp.wp_max_ad_count) AS avg_max_ad_count,
    SUM(CASE WHEN creation_dim.d_year = closed_dim.d_year THEN 1 ELSE 0 END) AS pages_created_same_year,
    SUM(CASE WHEN access_dim.d_year = closed_dim.d_year THEN 1 ELSE 0 END) AS pages_accessed_same_year,
    SUM(CASE WHEN creation_dim.d_month_seq = access_dim.d_month_seq THEN 1 ELSE 0 END) AS pages_created_and_accessed_same_month,
    SUM(CASE WHEN date_diff('day', creation_dim.d_date, access_dim.d_date) > 30 THEN 1 ELSE 0 END) AS pages_long_lived_over_30_days,
    ROUND(
        100.0 * SUM(CASE WHEN access_dim.d_date > closed_dim.d_date THEN 1 ELSE 0 END) /
        NULLIF(COUNT(DISTINCT wp.wp_web_page_id), 0),
        2
    ) AS pct_accessed_after_closure
FROM store s
JOIN date_dim closed_dim
    ON s.s_closed_date_sk = closed_dim.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk <= closed_dim.d_date_sk
   AND wp.wp_access_date_sk >= closed_dim.d_date_sk
JOIN date_dim creation_dim
    ON wp.wp_creation_date_sk = creation_dim.d_date_sk
JOIN date_dim access_dim
    ON wp.wp_access_date_sk = access_dim.d_date_sk
WHERE s.s_closed_date_sk IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    closed_dim.d_year,
    closed_dim.d_quarter_name
HAVING COUNT(DISTINCT wp.wp_web_page_id) > 0
ORDER BY total_pages DESC
LIMIT 100
