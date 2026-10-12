SELECT
  t.t_hour AS hour_of_day,
  cd_ret.cd_gender AS returning_gender,
  cd_ret.cd_education_status AS returning_education,
  cd_ref.cd_marital_status AS refunded_marital_status,
  COUNT(DISTINCT r.cr_order_number) AS distinct_orders,
  SUM(r.cr_return_amount) AS total_return_amount,
  AVG(r.cr_net_loss) AS avg_net_loss,
  SUM(r.cr_fee) AS total_fees,
  SUM(r.cr_return_quantity) AS total_quantity
FROM catalog_returns r
JOIN time_dim t
  ON r.cr_returned_time_sk = t.t_time_sk
JOIN customer_demographics cd_ret
  ON r.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
  ON r.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
WHERE r.cr_warehouse_sk IN (1, 13, 16)
  AND r.cr_return_amount > 0
  AND t.t_hour BETWEEN 8 AND 20
  AND r.cr_call_center_sk = 34
GROUP BY
  t.t_hour,
  cd_ret.cd_gender,
  cd_ret.cd_education_status,
  cd_ref.cd_marital_status
HAVING COUNT(DISTINCT r.cr_order_number) > 5
ORDER BY total_return_amount DESC
LIMIT 100
