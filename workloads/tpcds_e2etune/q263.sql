SELECT
  wp.wp_type,
  COUNT(DISTINCT ws.ws_order_number) AS num_orders,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  SUM(ws.ws_quantity) AS total_quantity,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin
FROM web_sales ws
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_rec_start_date <= DATE '2023-01-01'
  AND (wp.wp_rec_end_date IS NULL OR wp.wp_rec_end_date >= DATE '2023-01-01')
  AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
  AND ws.ws_net_profit > 0
GROUP BY wp.wp_type
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 50
