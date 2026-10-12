SELECT
    cc.cc_name,
    sm.sm_type,
    s.s_city,
    d_sold.d_year,
    d_ship.d_day_name AS ship_day_name,
    CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS quantity_group,
    DATE_DIFF('day', d_cc_open.d_date, d_sold.d_date) AS days_since_cc_open,
    DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date) AS days_open_to_close,
    COUNT(*) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_net_paid) / NULLIF(SUM(cs.cs_ext_list_price), 0) AS net_to_list_ratio
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_sold.d_year BETWEEN 1995 AND 2000
  AND cc.cc_tax_percentage > 5.00
GROUP BY
    cc.cc_name,
    sm.sm_type,
    s.s_city,
    d_sold.d_year,
    d_ship.d_day_name,
    CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END,
    DATE_DIFF('day', d_cc_open.d_date, d_sold.d_date),
    DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date)
ORDER BY total_net_paid DESC
LIMIT 100
