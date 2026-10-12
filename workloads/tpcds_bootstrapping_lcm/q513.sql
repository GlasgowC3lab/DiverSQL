SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    d_sold.d_year,
    d_sold.d_quarter_name,
    hd.hd_income_band_sk,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    ROUND(SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS profit_margin,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
    AND s.s_state = 'CA'
    AND cc.cc_division = 1
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_name,
    hd.hd_income_band_sk
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
