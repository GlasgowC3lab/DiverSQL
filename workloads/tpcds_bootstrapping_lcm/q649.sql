SELECT
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city AS store_city,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    MIN(d_ship.d_year - d_sold.d_year) AS min_ship_to_sold_year_diff,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT s.s_store_id) AS distinct_store_count,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    CASE
        WHEN SUM(cs.cs_net_paid) > 1000000 THEN 'High'
        WHEN SUM(cs.cs_net_paid) > 500000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    SUM(cs.cs_net_paid) / NULLIF(cc.cc_employees, 0) AS net_paid_per_employee
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
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND d_cc_closed.d_year = 2001
  AND d_cc_open.d_year <= d_sold.d_year
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    cc.cc_employees
HAVING SUM(cs.cs_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
