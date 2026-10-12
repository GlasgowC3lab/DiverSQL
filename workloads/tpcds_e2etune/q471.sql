WITH item_agg AS (
  SELECT
    i_category,
    i_brand,
    COUNT(*) AS item_cnt,
    AVG(i_current_price) AS avg_price,
    SUM(i_wholesale_cost) AS total_wholesale
  FROM item
  WHERE i_rec_start_date <= DATE '2023-01-01'
    AND (i_rec_end_date IS NULL OR i_rec_end_date >= DATE '2023-01-01')
  GROUP BY i_category, i_brand
),
item_stats AS (
  SELECT
    i_category,
    i_brand,
    item_cnt,
    avg_price,
    total_wholesale,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY avg_price DESC) AS brand_price_rank
  FROM item_agg
),
address_stats AS (
  SELECT
    ca_state,
    ca_location_type,
    COUNT(*) AS address_cnt,
    AVG(ca_gmt_offset) AS avg_gmt_offset,
    SUM(CASE WHEN ca_zip LIKE '8%' THEN 1 ELSE 0 END) AS zip_start_8_cnt
  FROM customer_address
  WHERE ca_country = 'United States'
  GROUP BY ca_state, ca_location_type
)
SELECT
  a.ca_state,
  a.ca_location_type,
  i.i_category,
  i.i_brand,
  i.item_cnt,
  i.avg_price,
  a.address_cnt,
  a.avg_gmt_offset,
  i.total_wholesale,
  i.brand_price_rank,
  CASE WHEN i.brand_price_rank = 1 THEN 'TopBrand' ELSE 'OtherBrand' END AS brand_rank_flag,
  i.avg_price * a.avg_gmt_offset AS price_gmt_product
FROM address_stats a
JOIN item_stats i
  ON true
WHERE i.avg_price > 10
ORDER BY i.total_wholesale DESC, a.address_cnt DESC
LIMIT 100
