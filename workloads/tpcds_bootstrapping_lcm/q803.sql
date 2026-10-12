SELECT
    CONCAT(cc.cc_company_name, '-', s.s_store_name) AS cc_store,
    d_sold.d_year AS sold_year,
    CASE WHEN d_sold.d_year >= 2020 THEN '2020+' ELSE 'Pre-2020' END AS year_bucket,
    (d_sold.d_year - d_store_closed.d_year) AS sale_vs_store_year_diff,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    d_store_closed.d_year AS store_closed_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(*) AS total_rows,
    AVG(cs.cs_quantity) AS avg_quantity,
    CASE WHEN SUM(cs.cs_net_paid) > 500000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    CONCAT(cc.cc_company_name, '-', s.s_store_name),
    d_sold.d_year,
    CASE WHEN d_sold.d_year >= 2020 THEN '2020+' ELSE 'Pre-2020' END,
    (d_sold.d_year - d_store_closed.d_year),
    ca_bill.ca_state,
    ca_ship.ca_state,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    d_store_closed.d_year
HAVING SUM(cs.cs_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
