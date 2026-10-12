SELECT
    cc.cc_manager,
    cc.cc_city,
    cc.cc_state,
    dd_cc_open.d_year AS cc_open_year,
    dd_cc_closed.d_year AS cc_closed_year,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    dd_sold.d_year AS sold_year,
    dd_ship.d_month_seq AS ship_month_seq,
    ca_bill.ca_state AS billing_state,
    ca_ship.ca_state AS shipping_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN date_dim dd_cc_closed
    ON cc.cc_closed_date_sk = dd_cc_closed.d_date_sk
JOIN date_dim dd_cc_open
    ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_cc_closed.d_date_sk
WHERE dd_sold.d_year = 2002
GROUP BY
    cc.cc_manager,
    cc.cc_city,
    cc.cc_state,
    dd_cc_open.d_year,
    dd_cc_closed.d_year,
    s.s_store_name,
    s.s_city,
    s.s_state,
    dd_sold.d_year,
    dd_ship.d_month_seq,
    ca_bill.ca_state,
    ca_ship.ca_state
ORDER BY total_net_paid DESC
LIMIT 100
