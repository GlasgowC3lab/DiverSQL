SELECT
  cc.cc_name,
  cc.cc_city,
  d_open.d_year AS open_year,
  d_open.d_month_seq AS open_month,
  d_closed.d_year AS closed_year,
  d_closed.d_month_seq AS closed_month,
  s.s_store_name,
  s.s_city,
  s.s_state,
  d_sales.d_year AS sales_year,
  d_sales.d_month_seq AS sales_month,
  d_ship.d_year AS ship_year,
  d_ship.d_month_seq AS ship_month,
  SUM(ss.ss_net_paid_inc_tax) AS store_sales_total,
  SUM(ws.ws_net_paid_inc_tax) AS web_sales_total,
  SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
  COUNT(DISTINCT ws.ws_order_number) AS web_txns,
  AVG(ss.ss_quantity) AS avg_store_qty,
  AVG(ws.ws_quantity) AS avg_web_qty
FROM call_center cc
JOIN date_dim d_open
  ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
  ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN store_sales ss
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
  cc.cc_name,
  cc.cc_city,
  d_open.d_year,
  d_open.d_month_seq,
  d_closed.d_year,
  d_closed.d_month_seq,
  s.s_store_name,
  s.s_city,
  s.s_state,
  d_sales.d_year,
  d_sales.d_month_seq,
  d_ship.d_year,
  d_ship.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
