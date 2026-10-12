WITH wp_stats AS (
    SELECT
        wp_type,
        COUNT(*) AS page_cnt,
        SUM(wp_image_count) AS total_images,
        AVG(wp_char_count) AS avg_chars,
        MAX(wp_link_count) AS max_links
    FROM web_page
    WHERE wp_rec_start_date >= DATE '2021-01-01'
      AND wp_rec_end_date   <= DATE '2022-12-31'
    GROUP BY wp_type
    HAVING SUM(wp_image_count) > 1000
),
w_stats AS (
    SELECT
        w_state,
        w_city,
        COUNT(*) AS wh_cnt,
        SUM(w_warehouse_sq_ft) AS total_sqft,
        AVG(w_gmt_offset) AS avg_gmt_offset
    FROM warehouse
    WHERE w_country = 'United States'
    GROUP BY w_state, w_city
    HAVING COUNT(*) > 5
)
SELECT
    w.w_state,
    w.w_city,
    w.wh_cnt,
    w.total_sqft,
    w.avg_gmt_offset,
    wp.wp_type,
    wp.page_cnt,
    wp.total_images,
    wp.avg_chars,
    wp.max_links,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY wp.total_images DESC) AS type_rank
FROM w_stats w
JOIN wp_stats wp ON true
WHERE w.total_sqft > 20000
ORDER BY w.w_state, type_rank
LIMIT 100
