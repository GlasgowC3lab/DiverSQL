SELECT
    page_type,
    page_cnt,
    avg_links,
    total_chars,
    RANK() OVER (ORDER BY avg_links DESC) AS type_rank
FROM (
    SELECT
        wp.wp_type AS page_type,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        AVG(wp.wp_link_count) AS avg_links,
        SUM(wp.wp_char_count) AS total_chars
    FROM web_page wp
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_creation.d_fy_year = 1902
      AND d_access.d_weekend = 'Y'
    GROUP BY wp.wp_type
    HAVING COUNT(*) > 10
) sub
ORDER BY avg_links DESC
LIMIT 5
