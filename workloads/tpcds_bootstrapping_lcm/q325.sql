SELECT
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month_seq,
    s.s_store_name,
    s.s_state AS store_state,
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    (s.s_division_id * 10 + cc.cc_division) AS combined_division_code,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
    c.c_birth_month,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    SUM(ss.ss_ext_sales_price) / NULLIF(SUM(ss.ss_quantity), 0) AS avg_price_per_item,
    SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS profit_margin
FROM
    store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d_cust_first_sales
        ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
    JOIN date_dim d_cust_first_ship
        ON c.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2020 AND 2022
    AND s.s_state = 'TX'
    AND cc.cc_state = 'TX'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    cc.cc_state,
    (s.s_division_id * 10 + cc.cc_division),
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END,
    c.c_birth_month
HAVING
    SUM(ss.ss_ext_sales_price) > 5000
ORDER BY
    total_sales DESC
LIMIT 100
