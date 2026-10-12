WITH
  store_sales_agg AS (
    SELECT
      ss_store_sk,
      ss_sold_date_sk,
      SUM(ss_ext_sales_price) AS total_store_sales,
      SUM(ss_net_profit) AS total_store_profit
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_store_sk, ss_sold_date_sk
  ),
  catalog_sales_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 0
  )
SELECT
  s.s_store_name,
  d.d_date,
  cs.cs_order_number,
  cs.cs_quantity,
  cs.cs_ext_sales_price,
  cs.cs_net_profit,
  agg.total_store_sales,
  agg.total_store_profit,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY agg.total_store_sales DESC) AS store_sales_rank,
  CASE
    WHEN sm.sm_type = 'AIR' THEN 'Air Shipment'
    ELSE 'Other Shipment'
  END AS shipment_type_desc
FROM catalog_sales_sample cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer cu
  ON cs.cs_bill_customer_sk = cu.c_customer_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_sales_agg agg
  ON agg.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON agg.ss_store_sk = s.s_store_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND cu.c_preferred_cust_flag = 'Y'
  AND cp.cp_catalog_number IN (15, 17)
LIMIT 100
