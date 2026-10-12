SELECT
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    d_cc_closed.d_date AS cc_closed_date,
    d_cc_open.d_date AS cc_open_date,
    d_page_start.d_date AS page_start_date,
    d_page_end.d_date AS page_end_date,
    sum(cs.cs_net_paid) AS total_net_paid,
    sum(cs.cs_net_profit) AS total_net_profit,
    avg(cs.cs_quantity) AS avg_quantity,
    max(cs.cs_ext_discount_amt) AS max_discount,
    count(distinct cs.cs_order_number) AS distinct_order_cnt
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    d_cc_closed.d_date,
    d_cc_open.d_date,
    d_page_start.d_date,
    d_page_end.d_date
ORDER BY total_net_paid DESC
LIMIT 100
