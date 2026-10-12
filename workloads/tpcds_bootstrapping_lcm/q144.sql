SELECT
  s.s_store_id,
  s.s_store_name,
  w.web_site_id,
  w.web_name,
  d_sold.d_year,
  d_sold.d_month_seq,
  d_sold.d_day_name,
  t.t_hour,
  COUNT(DISTINCT ws.ws_order_number) AS orders,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_ext_discount_amt) AS total_discount,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_quantity) AS avg_quantity,
  SUM(CASE WHEN d_ship.d_weekend = 'Y' THEN ws.ws_ext_sales_price ELSE 0 END) AS weekend_sales,
  SUM(CASE WHEN d_ship.d_weekend = 'N' THEN ws.ws_ext_sales_price ELSE 0 END) AS weekday_sales,
  MAX(d_ship.d_date) AS max_ship_date,
  MIN(d_site_open.d_date) AS site_open_date,
  MAX(d_site_close.d_date) AS site_close_date
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
JOIN date_dim d_site_open
  ON w.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
  ON w.web_close_date_sk = d_site_close.d_date_sk
WHERE d_sold.d_year BETWEEN 2019 AND 2021
  AND w.web_state = 'CA'
  AND s.s_state = 'CA'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY
  s.s_store_id,
  s.s_store_name,
  w.web_site_id,
  w.web_name,
  d_sold.d_year,
  d_sold.d_month_seq,
  d_sold.d_day_name,
  t.t_hour
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
