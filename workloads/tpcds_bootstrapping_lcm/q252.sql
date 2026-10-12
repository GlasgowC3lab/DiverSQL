SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    d_ship.d_month_seq AS ship_month_seq,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM date_dim d
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d.d_year = 2001
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    d_ship.d_month_seq,
    d_cc_closed.d_year,
    d_cc_open.d_year
ORDER BY total_net_paid DESC
LIMIT 100
