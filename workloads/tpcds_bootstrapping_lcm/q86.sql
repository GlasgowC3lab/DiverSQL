SELECT
  cc.cc_division_name,
  s.s_state,
  sm.sm_type,
  sold_dd.d_year AS sold_year,
  sold_dd.d_quarter_seq AS sold_quarter,
  ship_dd.d_year AS ship_year,
  ship_dd.d_quarter_seq AS ship_quarter,
  COUNT(DISTINCT ws.ws_order_number) AS order_count,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_ext_discount_amt) AS total_discount,
  AVG(ws.ws_sales_price) AS avg_sales_price,
  SUM(ws.ws_net_profit) AS total_profit,
  (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS profit_margin
FROM call_center cc
JOIN date_dim sold_dd
  ON cc.cc_closed_date_sk = sold_dd.d_date_sk
JOIN date_dim open_dd
  ON cc.cc_open_date_sk = open_dd.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = sold_dd.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = sold_dd.d_date_sk
JOIN date_dim ship_dd
  ON ws.ws_ship_date_sk = ship_dd.d_date_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_quantity > 0
GROUP BY
  cc.cc_division_name,
  s.s_state,
  sm.sm_type,
  sold_dd.d_year,
  sold_dd.d_quarter_seq,
  ship_dd.d_year,
  ship_dd.d_quarter_seq
ORDER BY total_sales DESC
LIMIT 100
