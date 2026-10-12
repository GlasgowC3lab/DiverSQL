WITH city_store_stats AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        COUNT(DISTINCT s.s_store_id) AS store_cnt,
        SUM(s.s_floor_space) AS total_floor_space
    FROM customer_address ca
    JOIN store s
        ON ca.ca_state = s.s_state
       AND ca.ca_city = s.s_city
       AND ca.ca_gmt_offset = s.s_gmt_offset
    GROUP BY ca.ca_state, ca.ca_city
),
city_web_stats AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_cnt,
        AVG(wp.wp_image_count) AS avg_image_cnt,
        SUM(wp.wp_image_count) AS total_image_cnt
    FROM customer_address ca
    JOIN web_page wp
        ON ca.ca_address_sk = wp.wp_customer_sk
    WHERE ca.ca_location_type = 'single family'
    GROUP BY ca.ca_state, ca.ca_city
)
SELECT
    cs.ca_state,
    cs.ca_city,
    cs.store_cnt,
    cs.total_floor_space,
    ws.web_page_cnt,
    ws.avg_image_cnt,
    ws.total_image_cnt,
    RANK() OVER (ORDER BY ws.avg_image_cnt DESC) AS city_image_rank
FROM city_store_stats cs
JOIN city_web_stats ws
    ON cs.ca_state = ws.ca_state
   AND cs.ca_city = ws.ca_city
WHERE ws.web_page_cnt > 5
ORDER BY ws.avg_image_cnt DESC
LIMIT 100
