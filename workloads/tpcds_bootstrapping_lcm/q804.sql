SELECT
  cc.cc_state,
  cc.cc_city,
  s.s_state,
  s.s_city,
  ws.web_state,
  ws.web_city,
  d_sold.d_year,
  d_sold.d_month_seq,
  d_cc_closed.d_day_name AS cc_closed_day,
  d_ws_close.d_day_name AS ws_closed_day,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  AVG(cs.cs_quantity) AS avg_quantity,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  SUM(cs.cs_net_paid) / NULLIF(SUM(cs.cs_ext_discount_amt), 0) AS net_to_discount_ratio,
  CASE
    WHEN d_sold.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
    WHEN d_sold.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
    WHEN d_sold.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
    ELSE 'Q4'
  END AS quarter_label,
  (d_sold.d_month_seq % 2) AS month_mod_2
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_ws_close
  ON ws.web_close_date_sk = d_ws_close.d_date_sk
GROUP BY
  cc.cc_state,
  cc.cc_city,
  s.s_state,
  s.s_city,
  ws.web_state,
  ws.web_city,
  d_sold.d_year,
  d_sold.d_month_seq,
  d_cc_closed.d_day_name,
  d_ws_close.d_day_name,
  CASE
    WHEN d_sold.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
    WHEN d_sold.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
    WHEN d_sold.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
    ELSE 'Q4'
  END,
  (d_sold.d_month_seq % 2)
ORDER BY total_net_paid DESC
LIMIT 100
