WITH wp_agg AS (
    SELECT
        wp.wp_creation_date_sk,
        wp.wp_access_date_sk,
        COUNT(*) AS page_count,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_char_count) AS avg_char_count
    FROM web_page wp
    GROUP BY wp.wp_creation_date_sk, wp.wp_access_date_sk
)
SELECT
    cp.cp_catalog_number,
    cp.cp_type,
    d_start.d_year AS start_year,
    d_end.d_year AS end_year,
    s.s_store_name,
    s.s_state,
    s.s_zip,
    ws.web_name,
    ws.web_state,
    wp_agg.page_count,
    wp_agg.total_images,
    wp_agg.avg_char_count,
    d_start.d_month_seq AS start_month_seq,
    d_end.d_month_seq AS end_month_seq,
    d_store_closed.d_date AS store_closed_date,
    d_web_open.d_date AS site_open_date,
    d_web_close.d_date AS site_close_date,
    d_wp_creation.d_date AS page_creation_date,
    d_wp_access.d_date AS page_access_date,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY wp_agg.total_images DESC) AS rn_state
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_start.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_start.d_date_sk
JOIN date_dim d_web_open ON ws.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
JOIN wp_agg ON wp_agg.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_wp_creation ON wp_agg.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp_agg.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_start.d_year = d_end.d_year
ORDER BY wp_agg.total_images DESC
LIMIT 100
