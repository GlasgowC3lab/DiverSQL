SELECT
    t.t_hour,
    t.t_shift,
    bd.hd_buy_potential,
    sd.hd_vehicle_count,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_coupon_amt) AS total_coupon_amount
FROM catalog_sales cs
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN household_demographics bd
    ON cs.cs_bill_hdemo_sk = bd.hd_demo_sk
JOIN household_demographics sd
    ON cs.cs_ship_hdemo_sk = sd.hd_demo_sk
WHERE cs.cs_promo_sk IN (1096, 1170)
  AND cs.cs_coupon_amt > 0
  AND cs.cs_quantity >= 2
GROUP BY t.t_hour, t.t_shift, bd.hd_buy_potential, sd.hd_vehicle_count
HAVING SUM(cs.cs_ext_sales_price) > 5000
ORDER BY total_profit DESC
LIMIT 100
