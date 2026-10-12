WITH loss_by_center AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    r.r_reason_desc,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(hd_ref.hd_vehicle_count) AS avg_vehicle_count,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'LOSS' ELSE 'PROFIT' END AS profit_status
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  GROUP BY cc.cc_call_center_sk, cc.cc_name, r.r_reason_desc
)
SELECT
  cc_call_center_sk,
  cc_name,
  r_reason_desc,
  total_net_loss,
  total_return_amount,
  total_return_quantity,
  avg_vehicle_count,
  profit_status,
  RANK() OVER (PARTITION BY r_reason_desc ORDER BY total_net_loss DESC) AS net_loss_rank_by_reason,
  DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS overall_net_loss_dense_rank
FROM loss_by_center
WHERE total_return_quantity >= 5
ORDER BY r_reason_desc, net_loss_rank_by_reason
LIMIT 100
