SELECT
    cc.cc_city,
    cc.cc_manager,
    s.s_store_name,
    s.s_state,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    d_cc_closed.d_date AS call_center_closed_date,
    d_cc_open.d_date AS call_center_open_date,
    d_cp_start.d_date AS catalog_page_start_date,
    d_cp_end.d_date AS catalog_page_end_date,
    d_store_closed.d_year AS store_closed_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
    AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_store_closed ON cs.cs_sold_date_sk = d_store_closed.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
GROUP BY
    cc.cc_city,
    cc.cc_manager,
    s.s_store_name,
    s.s_state,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_sold.d_year,
    d_ship.d_month_seq,
    d_cc_closed.d_date,
    d_cc_open.d_date,
    d_cp_start.d_date,
    d_cp_end.d_date,
    d_store_closed.d_year
ORDER BY total_net_paid DESC
LIMIT 100
