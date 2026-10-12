SELECT
    cc.cc_division_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_quarter_name,
    CASE
        WHEN SUM(cs.cs_net_profit) >= 200000 THEN 'Very High Profit'
        WHEN SUM(cs.cs_net_profit) >= 100000 THEN 'High Profit'
        WHEN SUM(cs.cs_net_profit) >= 50000  THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(CASE WHEN cs.cs_coupon_amt > 0 THEN cs.cs_coupon_amt END) AS avg_coupon_amount,
    COUNT(*) AS transaction_count
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
CROSS JOIN store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
  AND d_ship.d_year = d_sold.d_year
  AND d_cc_open.d_year <= d_sold.d_year
  AND (d_cc_closed.d_year IS NULL OR d_cc_closed.d_year >= d_sold.d_year)
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_division_name,
    s.s_city,
    d_sold.d_year,
    d_sold.d_quarter_name
ORDER BY total_net_paid DESC
LIMIT 100
