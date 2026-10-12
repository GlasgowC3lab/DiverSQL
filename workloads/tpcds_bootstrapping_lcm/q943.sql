SELECT
    cc.cc_name AS call_center_name,
    d_cc_open.d_year AS open_year,
    d_cc_closed.d_year AS close_year,
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(d_sold.d_date) AS first_sold_date,
    MAX(d_ship.d_date) AS last_ship_date
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE d_sold.d_date BETWEEN d_cc_open.d_date AND d_cc_closed.d_date
  AND d_ship.d_date BETWEEN d_cc_open.d_date AND d_cc_closed.d_date
GROUP BY
    cc.cc_name,
    d_cc_open.d_year,
    d_cc_closed.d_year,
    s.s_store_name,
    s.s_state,
    cd_bill.cd_gender,
    cd_ship.cd_gender
ORDER BY total_net_paid DESC
LIMIT 100
