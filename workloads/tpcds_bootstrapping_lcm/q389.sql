SELECT
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_ship.d_date) AS last_ship_date,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages,
    COUNT(DISTINCT s.s_store_id) FILTER (WHERE d_store_closed.d_date = d_cust_first_sales.d_date) AS stores_closed_on_first_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    MAX(d_wp_creation.d_date) AS latest_web_page_creation,
    MAX(d_wp_access.d_date) AS latest_web_page_access
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_sales cs
    ON 1 = 1
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer cust
    ON cs.cs_bill_customer_sk = cust.c_customer_sk
JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN date_dim d_cust_first_sales
    ON cust.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN date_dim d_cust_first_ship
    ON cust.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = cust.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY cust.c_customer_id, cust.c_first_name, cust.c_last_name
ORDER BY total_net_paid DESC
LIMIT 100
