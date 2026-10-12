SELECT 
    ca.ca_country AS billing_country,
    ca.ca_state AS billing_state,
    ca_ship.ca_state AS shipping_state,
    wsite.web_name AS website,
    s.s_store_name AS store_name,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_quantity) AS total_quantity
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_open ON wsite.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON wsite.web_close_date_sk = d_close.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_close.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
  AND s.s_number_employees > 50
  AND wsite.web_gmt_offset IS NOT NULL
GROUP BY 
    ca.ca_country,
    ca.ca_state,
    ca_ship.ca_state,
    wsite.web_name,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
