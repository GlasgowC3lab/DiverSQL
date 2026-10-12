SELECT
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    i.i_category,
    i.i_brand,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    d_cc_closed.d_date AS cc_closed_date,
    d_cc_open.d_date AS cc_open_date,
    d_store_closed.d_date AS store_closed_date,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM call_center cc
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_store_closed ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2001
  AND d_ship.d_month_seq BETWEEN 1 AND 12
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    i.i_category,
    i.i_brand,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    d_cc_closed.d_date,
    d_cc_open.d_date,
    d_store_closed.d_date
HAVING SUM(cs.cs_net_profit) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
