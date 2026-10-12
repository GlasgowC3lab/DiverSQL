SELECT ws.ws_sold_date_sk,
       wp.wp_type,
       ws.ws_quantity,
       CASE WHEN ws.ws_quantity > 68 THEN 'Large' ELSE 'Small' END AS quantity_category,
       ws.ws_ext_sales_price * 1.05 AS sales_price_with_tax,
       (ws.ws_ext_sales_price - ws.ws_ext_discount_amt) AS net_sales,
       CASE WHEN wp.wp_char_count IS NULL THEN 0 ELSE wp.wp_char_count END AS char_count,
       ws.ws_net_profit / NULLIF(ws.ws_quantity, 0) AS profit_per_item,
       CONCAT(wp.wp_url, '/details') AS page_detail_url
FROM web_sales ws
INNER JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_type = 'protected                                         '
  AND ws.ws_sold_date_sk = 2451037
