SELECT
    cc.cc_market_manager,
    cc.cc_name AS call_center_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_cc_close.d_year AS call_center_closed_year,
    d_cc_open.d_year AS call_center_open_year,
    d_cc_close.d_holiday AS store_closed_holiday,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(ss.ss_quantity) AS avg_quantity_per_ticket,
    MIN(c.c_birth_year) AS youngest_customer_birth_year,
    MAX(c.c_birth_year) AS oldest_customer_birth_year,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    MAX(d_ss_sold.d_holiday) FILTER (WHERE d_ss_sold.d_holiday IS NOT NULL) AS sale_day_holiday
FROM call_center cc
JOIN date_dim d_cc_close
    ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_close.d_date_sk
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss_sold
    ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d_c_first_ship
    ON c.c_first_shipto_date_sk = d_c_first_ship.d_date_sk
JOIN date_dim d_c_first_sales
    ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
WHERE d_ss_sold.d_year = 2020
  AND d_cc_close.d_holiday = 'Christmas'
GROUP BY
    cc.cc_market_manager,
    cc.cc_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_cc_close.d_year,
    d_cc_open.d_year,
    d_cc_close.d_holiday
ORDER BY total_ext_sales_price DESC
LIMIT 100
