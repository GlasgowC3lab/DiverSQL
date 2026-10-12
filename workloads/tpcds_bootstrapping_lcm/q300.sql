SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    s.s_store_name,
    s.s_state,
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    d_cc_closed.d_date AS call_center_closed_date,
    d_cc_open.d_date AS call_center_open_date,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0)) AS profit_margin
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_sold.d_year >= 2000
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_ship.d_month_seq,
    d_cc_closed.d_date,
    d_cc_open.d_date
ORDER BY total_net_paid DESC
LIMIT 100
