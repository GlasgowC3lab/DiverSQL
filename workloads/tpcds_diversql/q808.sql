WITH
  filtered_sales AS (
    SELECT *
    FROM catalog_sales
    WHERE cs_ext_sales_price > 1000
      AND cs_quantity BETWEEN 1 AND 10
      AND cs_ext_ship_cost < 500
      AND cs_net_paid_inc_ship > 2000
      AND cs_wholesale_cost IS NOT NULL
      AND cs_list_price <= 15000
  ),
  call_center_filtered AS (
    SELECT *
    FROM call_center
    WHERE cc_state = 'CA'
      AND cc_city = 'San Francisco'
      AND cc_employees > 50
      AND cc_sq_ft >= 1000
      AND cc_gmt_offset = -8.00
      AND cc_tax_percentage < 8.5
  ),
  item_filtered AS (
    SELECT *
    FROM item
    WHERE i_manufact_id IN (52, 264, 995)
      AND i_color = 'Red'
      AND i_size = 'M'
      AND i_units = 'Each'
      AND i_manager_id = 11
      AND i_current_price BETWEEN 10 AND 500
  ),
  common_cc AS (
    SELECT cs_call_center_sk FROM filtered_sales
    INTERSECT
    SELECT cc_call_center_sk FROM call_center_filtered
  ),
  sales_with_cc AS (
    SELECT fs.*, cc.cc_name, cc.cc_state
    FROM filtered_sales fs
    FULL OUTER JOIN call_center_filtered cc
      ON fs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE fs.cs_call_center_sk IN (SELECT cs_call_center_sk FROM common_cc)
       OR cc.cc_call_center_sk IN (SELECT cs_call_center_sk FROM common_cc)
  ),
  sales_item_join AS (
    SELECT swc.*, i.i_product_name, i.i_current_price
    FROM sales_with_cc swc
    JOIN item_filtered i
      ON swc.cs_item_sk = i.i_item_sk
  )
SELECT
  si.cc_name,
  si.cc_state,
  si.i_product_name,
  SUM(si.cs_ext_sales_price) AS total_sales,
  AVG(si.cs_net_paid_inc_ship) AS avg_net_paid_inc_ship,
  COUNT(*) AS transaction_count,
  MIN(si.cs_ext_ship_cost) AS min_ship_cost,
  MAX(si.cs_ext_ship_cost) AS max_ship_cost,
  (SUM(si.cs_ext_sales_price) * mult.multiplier) AS scaled_sales
FROM sales_item_join si
CROSS JOIN (VALUES (1), (2), (5)) AS mult(multiplier)
LEFT JOIN LATERAL (
  SELECT i2.i_item_sk, i2.i_product_name
  FROM item i2
  WHERE i2.i_item_sk = si.cs_item_sk
  ORDER BY i2.i_current_price DESC
  LIMIT 1
) AS top_item ON TRUE
GROUP BY
  si.cc_name,
  si.cc_state,
  si.i_product_name,
  mult.multiplier
ORDER BY total_sales DESC
LIMIT 100
