SELECT
    CASE WHEN ca_bill.ca_country = 'USA' THEN 'Domestic' ELSE 'International' END AS billing_region,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    d_creation.d_year AS creation_year,
    d_creation.d_month_seq AS creation_month,
    d_access.d_year AS access_year,
    d_access.d_month_seq AS access_month,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    ca_bill.ca_state AS billing_state,
    ca_ship.ca_state AS shipping_state,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_ext_tax) AS total_tax,
    SUM(ws.ws_sales_price * ws.ws_quantity * s.s_tax_percentage / 100) AS estimated_tax,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM web_sales ws
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    CASE WHEN ca_bill.ca_country = 'USA' THEN 'Domestic' ELSE 'International' END,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    d_creation.d_year,
    d_creation.d_month_seq,
    d_access.d_year,
    d_access.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca_bill.ca_state,
    ca_ship.ca_state
HAVING SUM(ws.ws_quantity) > 500
ORDER BY sold_year DESC, sold_month DESC, s.s_store_name
LIMIT 100
