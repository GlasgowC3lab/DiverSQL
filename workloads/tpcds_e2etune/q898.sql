SELECT
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COUNT(*) AS num_returns,
  SUM(cr.cr_net_loss) AS total_net_loss,
  SUM(cr.cr_refunded_cash) AS total_refunded_cash,
  AVG(cr.cr_return_quantity) AS avg_return_qty,
  AVG(r_hd.hd_vehicle_count) AS avg_returning_vehicle_cnt,
  AVG(f_hd.hd_vehicle_count) AS avg_refunded_vehicle_cnt,
  SUM(cr.cr_fee) AS total_fee
FROM catalog_returns cr
JOIN household_demographics r_hd
  ON cr.cr_returning_hdemo_sk = r_hd.hd_demo_sk
JOIN household_demographics f_hd
  ON cr.cr_refunded_hdemo_sk = f_hd.hd_demo_sk
JOIN income_band ib
  ON r_hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE cr.cr_return_quantity > 10
  AND cr.cr_fee > 20
  AND cr.cr_reason_sk IN (51, 50, 59)
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(*) >= 5
ORDER BY total_net_loss DESC
LIMIT 10
