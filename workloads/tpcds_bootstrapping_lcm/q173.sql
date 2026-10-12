SELECT
    d_sales.d_year AS sales_year,
    d_sales.d_current_month AS sales_month,
    s.s_state AS store_state,
    i.i_category AS item_category,
    cc.cc_division_name AS call_center_division,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS profit_margin,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
    COUNT(DISTINCT s.s_store_id) AS distinct_stores,
    AVG(date_diff('day', d_store_closed.d_date, d_cc_open.d_date)) AS avg_days_store_closed_to_cc_open
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sales.d_year >= 2020
GROUP BY
    d_sales.d_year,
    d_sales.d_current_month,
    s.s_state,
    i.i_category,
    cc.cc_division_name
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
