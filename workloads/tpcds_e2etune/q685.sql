WITH state_warehouse_stats AS (
  SELECT w_state,
         AVG(w_warehouse_sq_ft) AS avg_sqft,
         SUM(w_warehouse_sq_ft) AS total_sqft,
         COUNT(*) AS warehouse_cnt
  FROM warehouse
  WHERE w_warehouse_sq_ft > 300000
  GROUP BY w_state
),
page_aggregates AS (
  SELECT wp_type,
         COUNT(*) AS page_cnt,
         SUM(wp_image_count) AS total_images,
         SUM(wp_char_count) AS total_chars
  FROM web_page
  WHERE wp_rec_start_date >= DATE '2022-01-01'
  GROUP BY wp_type
)
SELECT w.w_state,
       w.w_warehouse_id,
       w.w_city,
       w.w_warehouse_sq_ft,
       s.avg_sqft,
       p.page_cnt,
       p.total_images,
       ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY w.w_warehouse_sq_ft DESC) AS warehouse_rank_in_state
FROM warehouse w
JOIN state_warehouse_stats s
  ON w.w_state = s.w_state
JOIN page_aggregates p
  ON p.wp_type = CASE 
                   WHEN w.w_gmt_offset = -7.00 THEN 'HOME'
                   WHEN w.w_gmt_offset = -6.00 THEN 'PRODUCT'
                   ELSE 'OTHER'
                 END
WHERE w.w_warehouse_sq_ft > s.avg_sqft
ORDER BY w.w_state, warehouse_rank_in_state
LIMIT 100
