SELECT
  cc.cc_state,
  s.s_state,
  cp.cp_type,
  d_sold.d_year AS sold_year,
  month(d_sold.d_date) AS sold_month,
  d_ship.d_year AS ship_year,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  AVG(cs.cs_quantity) AS avg_quantity,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  CASE WHEN cp.cp_type = 'PROMOTION' THEN 'Promo' ELSE 'Regular' END AS page_category,
  (SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_sales_price), 0)) * 100 AS discount_percent,
  AVG(date_diff('day', d_cc_open.d_date, d_store_closed.d_date)) AS avg_days_cc_open_to_store_close,
  AVG(date_diff('day', d_cp_start.d_date, d_cp_end.d_date)) AS avg_page_active_days
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_start
  ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sold.d_year >= 2000
GROUP BY
  cc.cc_state,
  s.s_state,
  cp.cp_type,
  d_sold.d_year,
  month(d_sold.d_date),
  d_ship.d_year,
  CASE WHEN cp.cp_type = 'PROMOTION' THEN 'Promo' ELSE 'Regular' END
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
