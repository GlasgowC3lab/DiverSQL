SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_cc_open.d_year AS cc_open_year,
    d_cc_closed.d_year AS cc_closed_year,
    d_cp_start.d_year AS cp_start_year,
    d_cp_end.d_year AS cp_end_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_sold.d_date) AS last_sale_date
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND d_sold.d_date BETWEEN d_cc_open.d_date AND d_cc_closed.d_date
  AND d_sold.d_date BETWEEN d_cp_start.d_date AND d_cp_end.d_date
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_cc_open.d_year,
    d_cc_closed.d_year,
    d_cp_start.d_year,
    d_cp_end.d_year
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 50
