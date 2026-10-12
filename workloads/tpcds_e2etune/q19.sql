SELECT
  ib.ib_income_band_sk,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(cs.cs_ext_sales_price - cs.cs_ext_discount_amt) AS total_gross_sales,
  AVG(cs.cs_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE cs.cs_ext_ship_cost > 200.00
  AND cs.cs_sales_price BETWEEN 50.00 AND 150.00
  AND hd_bill.hd_dep_count >= 2
  AND hd_ship.hd_vehicle_count > 1
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
