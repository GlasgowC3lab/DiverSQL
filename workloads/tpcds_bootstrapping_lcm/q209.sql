SELECT
    cc.cc_division,
    cc.cc_market_manager,
    st.s_city AS store_city,
    ca.ca_state AS customer_state,
    dd_sold.d_year,
    dd_sold.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_wholesale_cost) AS total_wholesale_cost,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    MIN(dd_sold.d_date) AS first_sale_date,
    MAX(dd_sold.d_date) AS last_sale_date,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL
        ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
    END AS profit_margin
FROM call_center cc
JOIN date_dim dd_closed
    ON cc.cc_closed_date_sk = dd_closed.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = dd_closed.d_date_sk
JOIN store_sales ss
    ON ss.ss_store_sk = st.s_store_sk
JOIN date_dim dd_sold
    ON ss.ss_sold_date_sk = dd_sold.d_date_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
WHERE dd_sold.d_year = 2022
GROUP BY
    cc.cc_division,
    cc.cc_market_manager,
    st.s_city,
    ca.ca_state,
    dd_sold.d_year,
    dd_sold.d_month_seq
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
