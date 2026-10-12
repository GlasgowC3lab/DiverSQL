WITH
  sales_agg AS (
    SELECT
      cs_item_sk,
      cs_promo_sk,
      cs_bill_customer_sk,
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_ship_mode_sk,
      cs_warehouse_sk,
      SUM(cs_ext_sales_price) AS sales_amount,
      SUM(cs_net_profit)       AS sales_profit,
      COUNT(*)                AS sales_cnt
    FROM catalog_sales
    GROUP BY
      cs_item_sk,
      cs_promo_sk,
      cs_bill_customer_sk,
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_ship_mode_sk,
      cs_warehouse_sk
  ),
  store_sales_agg AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      SUM(ss_ext_sales_price) AS store_sales_amount,
      SUM(ss_net_profit)       AS store_sales_profit,
      COUNT(*)                AS store_sales_cnt
    FROM store_sales
    GROUP BY ss_item_sk, ss_store_sk
  ),
  returns_agg AS (
    SELECT
      cr_item_sk,
      cr_reason_sk,
      SUM(cr_return_amount) AS return_amount,
      COUNT(*)              AS return_cnt
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_reason_sk
  ),
  call_center_agg AS (
    SELECT
      cr_call_center_sk,
      SUM(cr_return_amount) AS cc_return_amount,
      COUNT(*)              AS cc_return_cnt
    FROM catalog_returns
    GROUP BY cr_call_center_sk
  )
SELECT
  i.i_item_id,
  p.p_promo_id,
  s.s_state,
  buckets.bucket,
  SUM(sales_agg.sales_amount)        AS total_sales_amount,
  SUM(sales_agg.sales_profit)        AS total_sales_profit,
  SUM(store_sales_agg.store_sales_amount) AS total_store_sales_amount,
  SUM(store_sales_agg.store_sales_profit) AS total_store_sales_profit,
  SUM(returns_agg.return_amount)     AS total_return_amount,
  SUM(call_center_agg.cc_return_amount) AS total_cc_return_amount,
  COUNT(DISTINCT cust_bill.c_customer_id) AS distinct_bill_customers,
  COUNT(DISTINCT cust_web.c_customer_id)  AS distinct_web_customers
FROM sales_agg
JOIN item i
  ON sales_agg.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON sales_agg.cs_promo_sk = p.p_promo_sk
LEFT JOIN store_sales_agg
  ON store_sales_agg.ss_item_sk = i.i_item_sk
LEFT JOIN store s
  ON store_sales_agg.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg
  ON returns_agg.cr_item_sk = i.i_item_sk
LEFT JOIN reason r
  ON returns_agg.cr_reason_sk = r.r_reason_sk
JOIN call_center cc
  ON sales_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON sales_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON sales_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON sales_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer cust_bill
  ON sales_agg.cs_bill_customer_sk = cust_bill.c_customer_sk
LEFT JOIN customer_address ca_bill
  ON cust_bill.c_current_addr_sk = ca_bill.ca_address_sk
LEFT JOIN household_demographics hd_bill
  ON cust_bill.c_current_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN call_center_agg
  ON call_center_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN web_page wp
  ON TRUE
JOIN customer cust_web
  ON wp.wp_customer_sk = cust_web.c_customer_sk
LEFT JOIN customer_address ca_web
  ON cust_web.c_current_addr_sk = ca_web.ca_address_sk
LEFT JOIN household_demographics hd_web
  ON cust_web.c_current_hdemo_sk = hd_web.hd_demo_sk
CROSS JOIN (SELECT 1 AS bucket UNION ALL SELECT 2 UNION ALL SELECT 3) AS buckets
GROUP BY GROUPING SETS (
  (i.i_item_id, p.p_promo_id, buckets.bucket),
  (s.s_state, buckets.bucket),
  (buckets.bucket)
)
LIMIT 100
