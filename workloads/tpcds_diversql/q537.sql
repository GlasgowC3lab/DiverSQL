WITH sampled_items AS (
  SELECT *
  FROM item
  TABLESAMPLE BERNOULLI (10)
),
max_profit_scalar AS (
  SELECT MAX(cs_net_profit) AS max_profit
  FROM catalog_sales
),
item_keys_not_returned AS (
  SELECT cs_item_sk
  FROM catalog_sales
  EXCEPT
  SELECT sr_item_sk
  FROM store_returns
)
SELECT
  ca.ca_city,
  i.i_product_name,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_state_rank,
  'catalog' AS source
FROM catalog_sales cs
JOIN sampled_items i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
  ON i.i_item_sk = sr.sr_item_sk
WHERE sm.sm_carrier = 'AIRBORNE'
  AND p.p_discount_active = 'Y'
  AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
  AND hd.hd_vehicle_count >= 1
  AND cs.cs_net_profit > (SELECT max_profit FROM max_profit_scalar)
  AND i.i_item_sk IN (SELECT cs_item_sk FROM item_keys_not_returned)
GROUP BY ca.ca_city, ca.ca_state, i.i_product_name

UNION DISTINCT

SELECT
  ca2.ca_city,
  i2.i_product_name,
  SUM(wr.wr_return_amt) AS total_returns,
  RANK() OVER (PARTITION BY ca2.ca_state ORDER BY SUM(wr.wr_return_amt) DESC) AS returns_state_rank,
  'web' AS source
FROM web_returns wr
FULL OUTER JOIN sampled_items i2
  ON wr.wr_item_sk = i2.i_item_sk
JOIN customer_address ca2
  ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
JOIN household_demographics hd2
  ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
WHERE ca2.ca_location_type = 'condo'
  AND hd2.hd_dep_count = 0
  AND wr.wr_return_quantity > 0
  AND wr.wr_returned_date_sk BETWEEN 2450820 AND 2450830
GROUP BY ca2.ca_city, ca2.ca_state, i2.i_product_name
LIMIT 100
