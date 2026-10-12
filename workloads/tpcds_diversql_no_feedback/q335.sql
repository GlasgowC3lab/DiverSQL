WITH cs_filtered AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_call_center_sk,
    cs.cs_ship_mode_sk,
    cs.cs_net_paid,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_net_profit
  FROM catalog_sales cs
  WHERE cs.cs_ext_discount_amt > 1000
    AND cs.cs_net_paid > 500
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    AND cs.cs_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR')
    AND cs.cs_call_center_sk NOT IN (SELECT cc_call_center_sk FROM call_center WHERE cc_state = 'CA')
    AND cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'Brand#12')
),
ss_filtered AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit
  FROM store_sales ss
  WHERE ss.ss_quantity > 5
    AND ss.ss_ext_sales_price > 2000
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    AND ss.ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
    AND ss.ss_ticket_number NOT IN (SELECT cs_order_number FROM catalog_sales WHERE cs_ext_discount_amt > 5000)
    AND ss.ss_ticket_number > 1000000
),
exclude_keys AS (
  SELECT cs_order_number FROM catalog_sales WHERE cs_ext_discount_amt > 15000
  EXCEPT
  SELECT ss_ticket_number FROM store_sales WHERE ss_ext_sales_price < 1000
),
joined_all AS (
  SELECT
    cs.cs_order_number,
    ss.ss_ticket_number,
    d.d_year,
    i.i_brand,
    sm.sm_type,
    cc.cc_name,
    cs.cs_net_paid,
    ss.ss_ext_sales_price AS ss_sales,
    cs.cs_net_profit AS cs_profit,
    ss.ss_net_profit AS ss_profit
  FROM cs_filtered cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN store_sales ss ON ss.ss_item_sk = cs.cs_item_sk
  JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
)
SELECT
  cs_order_number,
  ss_ticket_number,
  d_year,
  i_brand,
  sm_type,
  cc_name,
  cs_net_paid,
  ss_sales,
  cs_profit,
  ss_profit,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY cs_net_paid DESC) AS rn_year,
  RANK() OVER (ORDER BY (cs_net_paid + ss_sales) DESC) AS overall_rank,
  CASE
    WHEN cs_profit > ss_profit THEN 'CatalogHigher'
    WHEN cs_profit < ss_profit THEN 'StoreHigher'
    ELSE 'Equal'
  END AS profit_comparison
FROM joined_all
WHERE cs_order_number NOT IN (SELECT cs_order_number FROM exclude_keys)
  AND cs_order_number NOT IN (
    SELECT cs_order_number FROM catalog_sales WHERE cs_ext_discount_amt > 20000
  )
ORDER BY overall_rank
LIMIT 100
