SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d_cc_open.d_year AS cc_open_year,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_count
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d_cc_open.d_year,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_ship.d_year,
    d_ship.d_month_seq,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
