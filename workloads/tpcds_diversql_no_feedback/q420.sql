SELECT ws.ws_order_number,
       wp.wp_url,
       ws.ws_quantity,
       ws.ws_net_paid_inc_ship_tax
FROM tpcds.web_sales ws
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_max_ad_count = 2
  AND ws.ws_quantity > 30
ORDER BY ws.ws_net_paid_inc_ship_tax DESC
LIMIT 100
