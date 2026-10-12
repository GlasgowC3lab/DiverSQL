SELECT
    cc.cc_call_center_id,
    cc.cc_market_manager,
    s.s_store_id,
    s.s_market_manager,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    d_store_closed.d_year AS store_closed_year,
    d_cc_closed.d_year AS cc_closed_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_sold.d_date) AS last_sale_date,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 1000000 THEN 'HIGH'
        ELSE 'LOW'
    END AS sales_category
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    cc.cc_call_center_id,
    cc.cc_market_manager,
    s.s_store_id,
    s.s_market_manager,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_store_closed.d_year,
    d_cc_closed.d_year
HAVING SUM(ss.ss_ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
