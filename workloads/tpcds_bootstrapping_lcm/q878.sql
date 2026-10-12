SELECT
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_state AS shipping_state,
    d_sold.d_year AS order_year,
    d_ship.d_month_seq AS shipping_month_seq,
    s.s_store_name,
    s.s_market_desc,
    wp.wp_type,
    wp.wp_url,
    d_page_creation.d_day_name AS page_creation_day,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_sales_price) AS avg_sales_price
FROM web_sales ws
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year >= 2010
GROUP BY
    ca_bill.ca_city,
    ca_ship.ca_state,
    d_sold.d_year,
    d_ship.d_month_seq,
    s.s_store_name,
    s.s_market_desc,
    wp.wp_type,
    wp.wp_url,
    d_page_creation.d_day_name
ORDER BY total_net_profit DESC
LIMIT 100
