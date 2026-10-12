WITH agg AS (
    SELECT
        p.p_channel_email,
        cp.cp_department,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_pages,
        SUM(p.p_cost) AS total_cost,
        AVG(wp.wp_image_count) AS avg_image_count,
        MAX(cp.cp_catalog_number) AS max_catalog_number
    FROM promotion p
    JOIN catalog_page cp
      ON cp.cp_start_date_sk <= p.p_end_date_sk
      AND cp.cp_end_date_sk >= p.p_start_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = cp.cp_start_date_sk
    WHERE p.p_cost > 0
      AND cp.cp_department = 'DEPARTMENT'
    GROUP BY p.p_channel_email, cp.cp_department
    HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) >= 2
)
SELECT
    p_channel_email,
    cp_department,
    num_pages,
    total_cost,
    avg_image_count,
    max_catalog_number,
    RANK() OVER (ORDER BY total_cost DESC) AS cost_rank
FROM agg
ORDER BY total_cost DESC
LIMIT 10
