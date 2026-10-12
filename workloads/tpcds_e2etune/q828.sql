WITH page_stats AS (
    SELECT
        wp.wp_type,
        COUNT(DISTINCT wp.wp_web_page_sk) AS total_pages,
        SUM(wp.wp_image_count) AS total_images,
        SUM(wp.wp_link_count) AS total_links,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
        CASE WHEN SUM(wp.wp_link_count) = 0 THEN NULL
             ELSE CAST(SUM(wp.wp_image_count) AS double) / SUM(wp.wp_link_count)
        END AS image_to_link_ratio
    FROM web_page wp
    JOIN date_dim cd ON wp.wp_creation_date_sk = cd.d_date_sk
    LEFT JOIN inventory i ON i.inv_date_sk = cd.d_date_sk
    WHERE cd.d_year = 2022
      AND cd.d_holiday = 'N'
    GROUP BY wp.wp_type
    HAVING COUNT(DISTINCT wp.wp_web_page_sk) >= 5
)
SELECT
    ps.wp_type,
    ps.total_pages,
    ps.total_images,
    ps.total_links,
    ps.avg_inventory_qty,
    ps.image_to_link_ratio,
    RANK() OVER (ORDER BY ps.avg_inventory_qty DESC) AS rank_by_inventory
FROM page_stats ps
ORDER BY ps.avg_inventory_qty DESC
LIMIT 10
