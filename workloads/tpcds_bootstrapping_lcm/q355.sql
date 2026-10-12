SELECT
    d_sold.d_year AS sales_year,
    d_sold.d_quarter_name AS sales_quarter,
    cc.cc_country,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(c_bill.c_birth_year) AS avg_bill_customer_birth_year,
    MAX(d_closed.d_year) AS cc_store_closed_year,
    MIN(d_cc_open.d_year) AS cc_open_year,
    MIN(d_cust_first_sales.d_year) AS first_sales_year,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN 1 ELSE 0 END) AS orders_with_coupon,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_net_paid) / NULLIF(SUM(cs.cs_quantity), 0) AS avg_price_per_quantity
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_cust_first_sales
    ON c_bill.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
WHERE d_sold.d_year >= 1995
  AND cs.cs_net_paid > 0
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    cc.cc_country,
    s.s_state
HAVING COUNT(DISTINCT cs.cs_order_number) > 5
ORDER BY total_net_paid DESC
LIMIT 100
