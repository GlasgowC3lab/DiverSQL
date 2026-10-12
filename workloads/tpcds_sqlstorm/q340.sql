SELECT d.d_year,
       i.i_category,
       ca.ca_state,
       p.p_promo_name,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_net_profit) AS total_profit,
       AVG(ws.ws_ext_discount_amt) AS avg_discount,
       COUNT(DISTINCT ws.ws_order_number) AS orders
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND i.i_category = 'Sports'
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
GROUP BY d.d_year, i.i_category, ca.ca_state, p.p_promo_name
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 10
