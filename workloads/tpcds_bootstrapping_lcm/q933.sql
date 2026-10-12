SELECT
  cc.cc_call_center_sk,
  cc.cc_company_name,
  s.s_store_sk,
  s.s_store_name,
  CASE
    WHEN sm.sm_type = 'AIR' THEN 'Air'
    WHEN sm.sm_type = 'RAIL' THEN 'Rail'
    ELSE 'Other'
  END AS shipping_category,
  d_sold.d_year,
  d_sold.d_moy,
  date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS cc_lifespan_days,
  SUM(ws.ws_net_profit) AS total_net_profit,
  SUM(ws.ws_quantity) AS total_quantity,
  AVG(ws.ws_sales_price) AS avg_sales_price,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_sold.d_year = 2022
  AND sm.sm_type IN ('AIR', 'RAIL')
GROUP BY
  cc.cc_call_center_sk,
  cc.cc_company_name,
  s.s_store_sk,
  s.s_store_name,
  CASE
    WHEN sm.sm_type = 'AIR' THEN 'Air'
    WHEN sm.sm_type = 'RAIL' THEN 'Rail'
    ELSE 'Other'
  END,
  d_sold.d_year,
  d_sold.d_moy,
  d_cc_open.d_date,
  d_cc_closed.d_date
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
