SELECT
  s.s_store_id,
  s.s_city,
  ws_open.web_name AS website_name,
  ws_open.web_state AS website_state,
  d_sold.d_year AS sold_year,
  d_sold.d_month_seq AS sold_month,
  d_ship.d_month_seq AS ship_month,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cs.cs_net_paid) AS total_net_paid,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  AVG(cs.cs_quantity) AS avg_quantity,
  MAX(wp_creation.wp_char_count) AS max_page_char_count,
  MIN(wp_creation.wp_char_count) AS min_page_char_count,
  CASE
    WHEN d_ship.d_month_seq = d_sold.d_month_seq THEN 'SameMonth'
    ELSE 'DifferentMonth'
  END AS month_relation
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_site ws_open ON ws_open.web_open_date_sk = d_sold.d_date_sk
JOIN web_site ws_close ON ws_close.web_close_date_sk = d_ship.d_date_sk
JOIN web_page wp_creation ON wp_creation.wp_creation_date_sk = d_sold.d_date_sk
JOIN web_page wp_access ON wp_access.wp_access_date_sk = d_ship.d_date_sk
WHERE cs.cs_net_paid > 0
GROUP BY
  s.s_store_id,
  s.s_city,
  ws_open.web_name,
  ws_open.web_state,
  d_sold.d_year,
  d_sold.d_month_seq,
  d_ship.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
