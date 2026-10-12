SELECT
  r_hd.hd_income_band_sk AS returning_income_band,
  r_hd.hd_vehicle_count AS returning_vehicle_count,
  r_hd.hd_buy_potential AS returning_buy_potential,
  f_hd.hd_income_band_sk AS refunded_income_band,
  COUNT(*) AS num_returns,
  SUM(wr.wr_return_quantity) AS total_quantity,
  SUM(wr.wr_net_loss) AS total_net_loss,
  AVG(wr.wr_return_amt) AS avg_return_amount
FROM web_returns AS wr
JOIN household_demographics AS r_hd
  ON wr.wr_returning_hdemo_sk = r_hd.hd_demo_sk
JOIN household_demographics AS f_hd
  ON wr.wr_refunded_hdemo_sk = f_hd.hd_demo_sk
WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
  AND wr.wr_item_sk IN (81038, 68140)
  AND r_hd.hd_income_band_sk IN (3, 4, 5)
  AND f_hd.hd_income_band_sk IN (3, 4, 5)
GROUP BY
  r_hd.hd_income_band_sk,
  r_hd.hd_vehicle_count,
  r_hd.hd_buy_potential,
  f_hd.hd_income_band_sk
HAVING SUM(wr.wr_net_loss) > 500
ORDER BY total_net_loss DESC
LIMIT 50
