SELECT
    cc.cc_call_center_id,
    cc.cc_market_manager,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sold.d_year AS sale_year,
    d_sold.d_moy AS sale_month,
    d_cc_open.d_year AS cc_open_year,
    d_store_closed.d_year AS store_closed_year,
    d_c_first_shipto.d_year AS first_shipto_year,
    d_c_first_sales.d_year AS first_sales_year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(ss.ss_sales_price) AS avg_sales_price
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d_c_first_shipto
    ON c.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
JOIN date_dim d_c_first_sales
    ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
GROUP BY
    cc.cc_call_center_id,
    cc.cc_market_manager,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_moy,
    d_cc_open.d_year,
    d_store_closed.d_year,
    d_c_first_shipto.d_year,
    d_c_first_sales.d_year
ORDER BY total_net_profit DESC
LIMIT 100
