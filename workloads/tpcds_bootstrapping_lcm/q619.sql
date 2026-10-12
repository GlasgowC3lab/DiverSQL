SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    MAX(cs.cs_net_profit) AS max_net_profit,
    ROUND(SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0), 4) AS net_profit_margin,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MIN(d_cc_closed.d_date) AS call_center_closed_date
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
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND cc.cc_country = 'United States'
  AND s.s_state = 'TX'
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cd_bill.cd_gender,
    cd_ship.cd_gender
HAVING SUM(cs.cs_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 50
