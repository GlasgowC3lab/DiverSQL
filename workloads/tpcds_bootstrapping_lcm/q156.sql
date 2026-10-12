SELECT
    cc.cc_company_name,
    cc.cc_manager,
    cc_open.d_date AS cc_open_date,
    cc_closed.d_date AS cc_closed_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count
FROM call_center cc
JOIN date_dim cc_open
    ON cc.cc_open_date_sk = cc_open.d_date_sk
JOIN date_dim cc_closed
    ON cc.cc_closed_date_sk = cc_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = cc_closed.d_date_sk
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    cc.cc_company_name,
    cc.cc_manager,
    cc_open.d_date,
    cc_closed.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_sales.d_year,
    d_sales.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
