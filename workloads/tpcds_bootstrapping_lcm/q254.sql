SELECT
  d_sold.d_year AS sold_year,
  d_sold.d_quarter_name AS sold_quarter,
  d_ship.d_month_seq AS ship_month_seq,
  wsit.web_name,
  st.s_store_name,
  COUNT(DISTINCT ws.ws_order_number) AS num_orders,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
  SUM(ws.ws_quantity) AS total_quantity,
  MIN(d_ship.d_date) AS earliest_ship_date,
  MAX(d_ship.d_date) AS latest_ship_date,
  MIN(d_sold.d_date) AS earliest_sold_date,
  MAX(d_sold.d_date) AS latest_sold_date,
  d_site_open.d_year AS site_open_year,
  d_site_close.d_year AS site_close_year
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN date_dim d_site_open
  ON wsit.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
  ON wsit.web_close_date_sk = d_site_close.d_date_sk
JOIN store st
  ON st.s_closed_date_sk = d_site_close.d_date_sk
WHERE d_sold.d_year >= 2020
  AND ws.ws_net_profit > 0
GROUP BY
  d_sold.d_year,
  d_sold.d_quarter_name,
  d_ship.d_month_seq,
  wsit.web_name,
  st.s_store_name,
  d_site_open.d_year,
  d_site_close.d_year
ORDER BY total_profit DESC
LIMIT 100
