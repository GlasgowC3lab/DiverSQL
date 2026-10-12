SELECT
  wr.wr_order_number,
  wr.wr_return_quantity,
  wr.wr_return_amt,
  wr.wr_return_tax,
  wr.wr_return_ship_cost,
  wr.wr_net_loss,
  hd.hd_income_band_sk,
  hd.hd_vehicle_count,
  (wr.wr_return_amt + wr.wr_return_tax + wr.wr_return_ship_cost) AS total_return_amount,
  (wr.wr_net_loss * (1 + 278.22)) AS net_loss_adjusted,
  CASE
    WHEN hd.hd_vehicle_count > 4 THEN 'High'
    WHEN hd.hd_vehicle_count = 4 THEN 'Medium'
    ELSE 'Low'
  END AS vehicle_category
FROM web_returns wr
INNER JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_income_band_sk = 14
