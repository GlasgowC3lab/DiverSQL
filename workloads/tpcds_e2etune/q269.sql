WITH wp_reason_warehouse AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_char_count,
        wp.wp_image_count,
        r.r_reason_desc,
        w.w_city,
        w.w_state,
        w.w_gmt_offset,
        w.w_warehouse_sq_ft
    FROM web_page wp
    JOIN reason r
        ON r.r_reason_sk = (wp.wp_web_page_sk % 5) + 1
    JOIN warehouse w
        ON w.w_warehouse_sk = (wp.wp_web_page_sk % 10) + 1
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND w.w_gmt_offset = -7.00
      AND wp.wp_char_count > 500
)
SELECT
    w_city,
    w_state,
    r_reason_desc,
    COUNT(*) AS page_count,
    AVG(wp_char_count) AS avg_char_count,
    SUM(wp_image_count) AS total_images,
    RANK() OVER (PARTITION BY w_city ORDER BY COUNT(*) DESC) AS city_reason_rank
FROM wp_reason_warehouse
GROUP BY w_city, w_state, r_reason_desc
HAVING COUNT(*) >= 10
ORDER BY w_city, page_count DESC
