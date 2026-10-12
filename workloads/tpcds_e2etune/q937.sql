SELECT
    ws.web_name,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
    SUM(wp.wp_image_count) AS total_images,
    AVG(wp.wp_link_count) AS avg_links,
    MAX(wp.wp_char_count) AS max_chars,
    MIN(wp.wp_char_count) AS min_chars,
    COUNT(r.r_reason_sk) AS reason_cnt,
    RANK() OVER (PARTITION BY ws.web_name ORDER BY SUM(wp.wp_image_count) DESC) AS image_rank
FROM web_page wp
JOIN ship_mode sm
    ON sm.sm_ship_mode_id = wp.wp_web_page_id
JOIN web_site ws
    ON ws.web_site_id = wp.wp_web_page_id
JOIN reason r
    ON r.r_reason_id = wp.wp_web_page_id
JOIN income_band ib
    ON ib.ib_income_band_sk = r.r_reason_sk
WHERE wp.wp_char_count > 5000
  AND sm.sm_type = 'AIR'
  AND ib.ib_upper_bound >= 30000
  AND r.r_reason_desc LIKE '%damaged%'
GROUP BY
    ws.web_name,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING COUNT(DISTINCT wp.wp_web_page_sk) > 2
ORDER BY total_images DESC, ws.web_name
LIMIT 100
