SELECT
    cc.cc_company_name,
    cc.cc_state,
    dd_cc_closed.d_year AS cc_closed_year,
    dd_cc_open.d_year AS cc_open_year,
    dd_sold.d_year AS sold_year,
    dd_sold.d_month_seq AS sold_month,
    dd_store_closed.d_year AS store_closed_year,
    i.i_category,
    i.i_brand,
    i.i_color,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_quantity) AS avg_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM store_sales ss
JOIN date_dim dd_sold
    ON ss.ss_sold_date_sk = dd_sold.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim dd_store_closed
    ON s.s_closed_date_sk = dd_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_cc_open
    ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
JOIN date_dim dd_cc_closed
    ON cc.cc_closed_date_sk = dd_cc_closed.d_date_sk
WHERE
    i.i_category = 'Electronics'
    AND s.s_state = 'CA'
    AND dd_sold.d_year = 2022
GROUP BY
    cc.cc_company_name,
    cc.cc_state,
    dd_cc_closed.d_year,
    dd_cc_open.d_year,
    dd_sold.d_year,
    dd_sold.d_month_seq,
    dd_store_closed.d_year,
    i.i_category,
    i.i_brand,
    i.i_color,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY total_sales DESC
LIMIT 100
