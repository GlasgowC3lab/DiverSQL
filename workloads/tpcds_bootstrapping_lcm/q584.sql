SELECT
  d_sold.d_year AS sold_year,
  d_sold.d_month_seq AS sold_month_seq,
  d_ship.d_year AS ship_year,
  d_ship.d_month_seq AS ship_month_seq,
  s.s_state AS store_state,
  wp.wp_type AS page_type,
  COUNT(DISTINCT ws.ws_order_number) AS num_orders,
  SUM(ws.ws_net_paid) AS total_net_paid,
  SUM(ws.ws_net_profit) AS total_net_profit,
  AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
  SUM(ws.ws_quantity) AS total_quantity,
  MIN(d_page_creation.d_date) AS earliest_page_creation,
  MAX(d_page_access.d_date) AS latest_page_access,
  DATE_DIFF('day', MIN(d_page_creation.d_date), MAX(d_page_access.d_date)) AS page_lifespan_days,
  COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_ids,
  SUM(CASE WHEN ws.ws_coupon_amt > 0 THEN 1 ELSE 0 END) AS orders_with_coupon,
  ROUND(AVG(ws.ws_sales_price), 2) AS avg_sales_price,
  SUM(ws.ws_ext_sales_price) / NULLIF(SUM(ws.ws_quantity), 0) AS avg_price_per_item
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
  AND s.s_state IN ('CA', 'NY', 'TX')
  AND wp.wp_type IS NOT NULL
GROUP BY
  d_sold.d_year,
  d_sold.d_month_seq,
  d_ship.d_year,
  d_ship.d_month_seq,
  s.s_state,
  wp.wp_type
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
