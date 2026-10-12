SELECT
    s.s_store_name,
    s.s_city,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    wp.wp_url,
    wp.wp_type,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MAX(ws.ws_net_profit) AS max_profit,
    MIN(ws.ws_net_profit) AS min_profit,
    d_wp_creation.d_year AS page_creation_year,
    d_wp_access.d_year AS page_access_year,
    d_sold.d_day_name AS sold_day_name,
    d_ship.d_day_name AS ship_day_name
FROM store s
JOIN date_dim d_sold
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    ca_bill.ca_city,
    ca_ship.ca_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    wp.wp_url,
    wp.wp_type,
    d_wp_creation.d_year,
    d_wp_access.d_year,
    d_sold.d_day_name,
    d_ship.d_day_name
ORDER BY total_sales DESC
LIMIT 100
