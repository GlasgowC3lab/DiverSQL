SELECT
  CASE
    WHEN s.s_state IN ('CA','OR','WA','NV') THEN 'West'
    WHEN s.s_state IN ('NY','NJ','CT','MA') THEN 'Northeast'
    WHEN s.s_state IN ('TX','OK','NM','LA') THEN 'Southwest'
    ELSE 'Other'
  END AS region,
  d_end.d_year AS year,
  cp.cp_type,
  p.p_promo_name,
  COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_page_cnt,
  COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
  SUM(p.p_cost) AS total_promo_cost,
  AVG(wp.wp_image_count) AS avg_image_count,
  SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_promos,
  SUM(p.p_cost) / NULLIF(COUNT(DISTINCT cp.cp_catalog_page_id), 0) AS cost_per_catalog_page,
  SUM(wp.wp_image_count) / NULLIF(COUNT(DISTINCT wp.wp_web_page_id), 0) AS avg_images_per_web_page
FROM date_dim d_end
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_end.d_date_sk
JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_end.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE s.s_state IS NOT NULL
  AND cp.cp_type IS NOT NULL
  AND p.p_promo_name IS NOT NULL
GROUP BY 1, 2, 3, 4
HAVING COUNT(DISTINCT cp.cp_catalog_page_id) > 0
ORDER BY total_promo_cost DESC
LIMIT 100
