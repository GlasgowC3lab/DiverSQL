SELECT d_sales.d_quarter_name AS quarter,
       sm_sales.sm_type AS ship_mode_type,
       wp.wp_type AS page_type,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
       (SUM(ws.ws_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_adjusted,
       COUNT(DISTINCT ws.ws_order_number) AS orders,
       COUNT(DISTINCT cr.cr_order_number) AS returns
FROM web_sales ws
JOIN date_dim d_sales
  ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN ship_mode sm_sales
  ON ws.ws_ship_mode_sk = sm_sales.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_sales.d_date_sk
  AND cr.cr_ship_mode_sk = sm_sales.sm_ship_mode_sk
WHERE d_sales.d_year = 2001
  AND sm_sales.sm_type = 'AIR'
  AND wp.wp_type = 'PRODUCT'
GROUP BY d_sales.d_quarter_name, sm_sales.sm_type, wp.wp_type
HAVING SUM(ws.ws_net_paid) > 50000
ORDER BY net_profit_adjusted DESC
LIMIT 100
