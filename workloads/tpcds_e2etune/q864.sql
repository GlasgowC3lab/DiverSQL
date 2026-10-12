WITH site_page_stats AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        ws.web_state,
        ws.web_open_date_sk,
        COUNT(wp.wp_web_page_id) AS page_cnt,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_image_count) AS avg_images
    FROM web_page wp
    JOIN web_site ws
        ON wp.wp_creation_date_sk = ws.web_open_date_sk
    GROUP BY ws.web_site_id, ws.web_name, ws.web_state, ws.web_open_date_sk
),
catalog_page_stats AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_type,
        cp.cp_start_date_sk,
        COUNT(wp.wp_web_page_id) AS linked_page_cnt,
        SUM(wp.wp_image_count) AS linked_total_images
    FROM catalog_page cp
    JOIN web_page wp
        ON cp.cp_start_date_sk = wp.wp_creation_date_sk
    GROUP BY cp.cp_catalog_page_id, cp.cp_description, cp.cp_type, cp.cp_start_date_sk
)
SELECT
    cps.cp_catalog_page_id,
    cps.cp_description,
    cps.cp_type,
    sps.web_site_id,
    sps.web_name,
    cps.linked_page_cnt,
    sps.page_cnt,
    cps.linked_total_images,
    sps.total_images,
    (cps.linked_total_images * 1.0 / NULLIF(sps.total_images, 0)) AS image_ratio,
    RANK() OVER (ORDER BY cps.linked_total_images DESC) AS catalog_image_rank,
    ROW_NUMBER() OVER (PARTITION BY sps.web_site_id ORDER BY cps.linked_total_images DESC) AS site_catalog_rank
FROM catalog_page_stats cps
JOIN site_page_stats sps
    ON cps.cp_start_date_sk = sps.web_open_date_sk
WHERE cps.cp_type = 'A'
  AND sps.web_state = 'CA'
  AND cps.linked_page_cnt >= 5
ORDER BY cps.linked_total_images DESC
LIMIT 50
