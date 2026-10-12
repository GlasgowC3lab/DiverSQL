WITH brand_stats AS (
    SELECT i_brand_id,
           AVG(i_current_price) AS avg_price,
           SUM(i_wholesale_cost) AS total_wholesale_cost,
           COUNT(*) AS item_cnt
    FROM item
    GROUP BY i_brand_id
)
SELECT cp.cp_type,
       ib.ib_income_band_sk,
       bs.i_brand_id,
       COUNT(*) AS num_items,
       SUM(i.i_current_price) AS total_current_price,
       AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
       MAX(i.i_current_price) AS max_current_price,
       MIN(i.i_current_price) AS min_current_price,
       bs.avg_price AS brand_average_price,
       bs.total_wholesale_cost AS brand_total_wholesale_cost
FROM catalog_page cp
JOIN item i
  ON cp.cp_catalog_number = i.i_category_id
JOIN income_band ib
  ON i.i_current_price BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
JOIN brand_stats bs
  ON i.i_brand_id = bs.i_brand_id
WHERE cp.cp_type = 'monthly'
  AND cp.cp_end_date_sk >= 2450905
  AND i.i_rec_start_date <= DATE '2025-12-31'
GROUP BY cp.cp_type,
         ib.ib_income_band_sk,
         bs.i_brand_id,
         bs.avg_price,
         bs.total_wholesale_cost
HAVING COUNT(*) >= 10
ORDER BY total_current_price DESC
LIMIT 100
