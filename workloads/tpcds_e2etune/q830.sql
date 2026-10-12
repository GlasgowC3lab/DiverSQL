WITH promo_stats AS (
  SELECT
    hd.hd_vehicle_count,
    w.w_country,
    COUNT(*) AS promo_cnt,
    AVG(p.p_cost) AS avg_cost,
    SUM(p.p_cost) AS total_cost,
    AVG(wp.wp_image_count) AS avg_img_cnt
  FROM promotion p
  JOIN household_demographics hd ON hd.hd_demo_sk = p.p_promo_sk
  JOIN warehouse w ON w.w_warehouse_sk = p.p_end_date_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = p.p_start_date_sk
  WHERE hd.hd_income_band_sk BETWEEN 3 AND 5
    AND p.p_cost > 1000
    AND wp.wp_image_count > 5
  GROUP BY hd.hd_vehicle_count, w.w_country
  HAVING COUNT(*) > 5
)
SELECT
  hd_vehicle_count,
  w_country,
  promo_cnt,
  avg_cost,
  total_cost,
  avg_img_cnt,
  RANK() OVER (ORDER BY total_cost DESC) AS rank_by_total_cost
FROM promo_stats
ORDER BY total_cost DESC
LIMIT 20
