/*
  Goal: Analyze total catalog sales and store‑sales metrics by warehouse and customer income band, retaining all warehouses (right‑outer join), applying realistic selective filters, and computing distinct counts of customers and orders. The query joins all 11 selected TPC‑DS tables using only the permitted join keys, includes a CROSS JOIN with a small computed set, groups by warehouse and income band, and limits the result to 100 rows.
*/
SELECT
  w.w_warehouse_name,
  ib.ib_income_band_sk,
  t.threshold,
  SUM(cs.cs_ext_sales_price)               AS total_sales,
  AVG(ss.ss_ext_tax)                       AS avg_tax,
  COUNT(DISTINCT c.c_customer_id)          AS distinct_customers,
  COUNT(DISTINCT cs.cs_order_number)       AS distinct_orders,
  MIN(ss.ss_ext_sales_price)               AS min_sales,
  MAX(ss.ss_ext_sales_price)               AS max_sales
FROM store_sales ss
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_sales cs
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
RIGHT OUTER JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN (VALUES (1), (2), (3)) AS t(threshold)
WHERE cs.cs_ext_sales_price > 500.00
  AND ss.ss_ext_tax > 20.00
  AND w.w_city = 'Seattle'
  AND ib.ib_lower_bound >= 60000
  AND site.web_state = 'CA'
GROUP BY w.w_warehouse_name, ib.ib_income_band_sk, t.threshold
ORDER BY total_sales DESC
LIMIT 100
