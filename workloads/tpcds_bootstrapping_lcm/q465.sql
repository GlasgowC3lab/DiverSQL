SELECT
  d_sold.d_year AS sale_year,
  d_sold.d_month_seq AS sale_month,
  d_ship.d_month_seq AS ship_month,
  s.s_state,
  s.s_city,
  wp.wp_type,
  CASE WHEN d_access.d_dow IN (6,7) THEN 'Weekend' ELSE 'Weekday' END AS access_day_type,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_sales_price) AS avg_sales_price,
  SUM(ws.ws_coupon_amt) AS total_coupons,
  ROUND(SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0), 4) AS profit_margin,
  SUM(CASE WHEN ws.ws_quantity > 5 THEN ws.ws_ext_sales_price ELSE 0 END) AS high_qty_sales,
  SUM(CASE WHEN wp.wp_autogen_flag = 'Y' THEN ws.ws_ext_sales_price ELSE 0 END) AS auto_page_sales,
  (d_sold.d_year * 100 + d_sold.d_month_seq) AS year_month_id,
  MIN(d_creation.d_date) AS earliest_page_creation_date
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE ws.ws_ext_sales_price > 0
  AND wp.wp_type IS NOT NULL
  AND d_sold.d_year BETWEEN 2019 AND 2022
GROUP BY
  d_sold.d_year,
  d_sold.d_month_seq,
  d_ship.d_month_seq,
  s.s_state,
  s.s_city,
  wp.wp_type,
  CASE WHEN d_access.d_dow IN (6,7) THEN 'Weekend' ELSE 'Weekday' END,
  (d_sold.d_year * 100 + d_sold.d_month_seq)
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
