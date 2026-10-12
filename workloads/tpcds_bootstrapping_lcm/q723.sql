SELECT
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_city AS shipping_city,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    wp.wp_type,
    wp.wp_url,
    d_ship.d_date AS ship_date,
    d_wp_creation.d_date AS page_creation_date,
    d_wp_access.d_date AS page_access_date,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_qty,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon,
    DATE_DIFF('day', d_wp_creation.d_date, d_wp_access.d_date) AS days_between_creation_and_access
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
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    ca_bill.ca_city,
    ca_ship.ca_city,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    wp.wp_type,
    wp.wp_url,
    d_ship.d_date,
    d_wp_creation.d_date,
    d_wp_access.d_date
ORDER BY total_profit DESC
LIMIT 50
