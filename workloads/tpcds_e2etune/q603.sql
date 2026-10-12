SELECT
  hd.hd_buy_potential,
  hd.hd_income_band_sk,
  COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
  SUM(ss.ss_ext_sales_price) AS gross_sales,
  SUM(ss.ss_quantity) AS total_units_sold,
  SUM(COALESCE(r.sr_return_quantity, 0)) AS total_units_returned,
  CASE WHEN SUM(ss.ss_quantity) = 0 THEN 0
       ELSE 100.0 * SUM(COALESCE(r.sr_return_quantity, 0)) / SUM(ss.ss_quantity) END AS return_rate_pct,
  SUM(ss.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) AS net_profit_after_returns,
  AVG(ss.ss_ext_discount_amt) AS avg_discount_per_sale,
  RANK() OVER (ORDER BY SUM(ss.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) DESC) AS profit_rank
FROM store_sales ss
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns r
  ON ss.ss_ticket_number = r.sr_ticket_number
  AND ss.ss_item_sk = r.sr_item_sk
  AND hd.hd_demo_sk = r.sr_hdemo_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450900 AND 2451053
  AND hd.hd_vehicle_count >= 1
  AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
GROUP BY hd.hd_buy_potential, hd.hd_income_band_sk
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 10
