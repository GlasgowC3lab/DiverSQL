SELECT
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month_seq,
    d_sold.d_day_name AS sales_day_name,
    t.t_hour AS sale_hour,
    t.t_am_pm AS sale_am_pm,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_days
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_sold.d_date BETWEEN d_cc_open.d_date AND d_cc_closed.d_date
  AND d_ship.d_date <= d_cc_closed.d_date
  AND cs.cs_quantity > 0
GROUP BY
    cc.cc_name,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    t.t_hour,
    t.t_am_pm
ORDER BY total_net_paid DESC
LIMIT 100
