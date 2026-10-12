SELECT
    c.c_customer_id,
    s.s_store_name,
    d_sales.d_year,
    CASE 
        WHEN s.s_state = 'CA' THEN 'West'
        WHEN s.s_state = 'NY' THEN 'East'
        ELSE 'Other'
    END AS region,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS transaction_count,
    AVG(ss.ss_quantity) AS avg_quantity,
    MAX(d_sales.d_month_seq) - MIN(d_sales.d_month_seq) AS month_span,
    SUM(CASE WHEN wp.wp_type = 'home' THEN 1 ELSE 0 END) AS home_page_visits,
    SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_visits
FROM customer c
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_c_first_shipto ON c.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
JOIN date_dim d_c_first_sales ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
WHERE d_sales.d_year BETWEEN 2015 AND 2020
GROUP BY
    c.c_customer_id,
    s.s_store_name,
    d_sales.d_year,
    CASE 
        WHEN s.s_state = 'CA' THEN 'West'
        WHEN s.s_state = 'NY' THEN 'East'
        ELSE 'Other'
    END
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
