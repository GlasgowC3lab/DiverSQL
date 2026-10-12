SELECT
  sm.sm_type,
  wp.wp_type,
  r.r_reason_desc,
  COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
  SUM(p.p_cost) AS total_cost,
  AVG(wp.wp_image_count) AS avg_image_cnt,
  RANK() OVER (PARTITION BY sm.sm_type ORDER BY SUM(p.p_cost) DESC) AS cost_rank
FROM promotion p
JOIN ship_mode sm ON p.p_promo_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON p.p_item_sk = wp.wp_customer_sk
JOIN reason r ON p.p_response_target = r.r_reason_sk
WHERE p.p_response_target = 1
  AND p.p_channel_tv = 'N'
  AND p.p_channel_radio = 'N'
  AND p.p_channel_catalog = 'N'
  AND p.p_channel_press = 'N'
  AND p.p_channel_email = 'N'
  AND p.p_start_date_sk BETWEEN 2450000 AND 2459999
  AND wp.wp_creation_date_sk BETWEEN 2450000 AND 2459999
GROUP BY sm.sm_type, wp.wp_type, r.r_reason_desc
HAVING SUM(p.p_cost) > 1000
ORDER BY total_cost DESC
LIMIT 100
