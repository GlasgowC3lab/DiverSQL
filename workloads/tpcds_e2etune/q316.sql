SELECT
    sm.sm_type AS ship_mode_type,
    hd.hd_income_band_sk AS income_band,
    COUNT(*) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    AVG(cs.cs_coupon_amt) AS avg_coupon
FROM catalog_sales cs
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE cs.cs_coupon_amt > 0
  AND cs.cs_ext_tax >= 20.00
  AND cs.cs_ext_sales_price BETWEEN 1000 AND 10000
GROUP BY sm.sm_type, hd.hd_income_band_sk
HAVING COUNT(*) >= 50
ORDER BY avg_net_profit DESC
LIMIT 20
