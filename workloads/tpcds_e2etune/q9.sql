WITH page_stats AS (
    SELECT
        c.c_salutation AS salutation,
        hd.hd_vehicle_count AS vehicle_count,
        AVG(wp.wp_link_count) AS avg_links,
        SUM(wp.wp_image_count) AS total_images,
        COUNT(*) AS page_cnt
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND wp.wp_type = 'article'
      AND hd.hd_vehicle_count >= 1
    GROUP BY c.c_salutation, hd.hd_vehicle_count
)
SELECT
    salutation,
    vehicle_count,
    avg_links,
    total_images,
    page_cnt,
    RANK() OVER (ORDER BY avg_links DESC) AS link_rank
FROM page_stats
ORDER BY link_rank
LIMIT 20
