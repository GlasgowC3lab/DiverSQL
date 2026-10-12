SELECT
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS month_seq,
    ca_bill.ca_state AS customer_state,
    w.w_country AS warehouse_country,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_quantity
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ca_bill.ca_county IN ('Maricopa County', 'York County')
  AND d_sold.d_year = 2022
  AND d_sold.d_month_seq = d_wp_creation.d_month_seq
  AND w.w_state = ca_bill.ca_state
  AND ws.ws_quantity > 0
GROUP BY d_sold.d_year, d_sold.d_month_seq, ca_bill.ca_state, w.w_country
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 50
