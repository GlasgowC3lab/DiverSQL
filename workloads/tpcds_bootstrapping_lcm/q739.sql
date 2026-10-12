SELECT
    cc.cc_name AS call_center_name,
    cc.cc_manager AS call_center_manager,
    d_open.d_year AS cc_open_year,
    d_open.d_month_seq AS cc_open_month,
    d_closed.d_year AS cc_closed_year,
    d_closed.d_month_seq AS cc_closed_month,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month,
    ca.ca_city AS customer_city,
    ca.ca_state AS customer_state,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(ss.ss_quantity) AS total_quantity
FROM store_sales ss
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_manager,
    d_open.d_year,
    d_open.d_month_seq,
    d_closed.d_year,
    d_closed.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    ca.ca_city,
    ca.ca_state
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_sales DESC
LIMIT 100
