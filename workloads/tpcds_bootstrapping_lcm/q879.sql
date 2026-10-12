SELECT
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    i.i_category,
    i.i_brand,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS total_sales,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_cc_closed.d_date) AS call_center_closed_date,
    MIN(d_store.d_date) AS store_closed_date
FROM store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_year = 2020
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    d_ship.d_month_seq,
    i.i_category,
    i.i_brand,
    d_cc_open.d_date,
    d_cc_closed.d_date,
    d_store.d_date
ORDER BY total_net_paid DESC
LIMIT 100
