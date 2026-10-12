SELECT c.c_customer_id,
       ws.ws_order_number,
       ws.ws_net_paid,
       ws.ws_ext_list_price
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ws.ws_ship_date_sk = 2452324
  AND c.c_first_sales_date_sk >= 2450890
ORDER BY ws.ws_net_paid DESC
LIMIT 10
