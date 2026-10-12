SELECT
    cc.cc_name AS call_center_name,
    w.w_warehouse_name AS warehouse_name,
    s.s_store_name AS store_name,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    CASE
        WHEN SUM(cs.cs_net_paid) = 0 THEN 0
        ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid)
    END AS profit_margin,
    MAX(cs.cs_ext_tax) AS max_tax,
    MIN(cs.cs_ext_tax) AS min_tax,
    DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date) AS call_center_days_open,
    DATE_DIFF('day', d_store.d_date, d_cc_closed.d_date) AS days_between_store_closed_and_cc_closed
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON true
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
  AND w.w_state = s.s_state
  AND w.w_warehouse_sq_ft > 50000
  AND d_ship.d_month_seq = d_sold.d_month_seq
GROUP BY
    cc.cc_name,
    w.w_warehouse_name,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_cc_open.d_date,
    d_cc_closed.d_date,
    d_store.d_date
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
