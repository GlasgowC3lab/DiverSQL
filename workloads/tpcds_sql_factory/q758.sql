WITH daily_stats AS (
  SELECT
    cc.cc_state,
    r.r_reason_desc,
    hd_ret.hd_vehicle_count,
    cr.cr_returned_date_sk AS return_date,
    SUM(cr.cr_net_loss) AS daily_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS daily_return_cnt
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  GROUP BY cc.cc_state, r.r_reason_desc, hd_ret.hd_vehicle_count, cr.cr_returned_date_sk
)
SELECT
  cc_state,
  return_date,
  r_reason_desc,
  hd_vehicle_count,
  daily_net_loss,
  avg_return_amount,
  daily_return_cnt,
  LAG(daily_net_loss) OVER (PARTITION BY cc_state ORDER BY return_date) AS prev_day_net_loss,
  CASE
    WHEN daily_net_loss > COALESCE(LAG(daily_net_loss) OVER (PARTITION BY cc_state ORDER BY return_date), 0) THEN 'UP'
    ELSE 'DOWN_OR_EQUAL'
  END AS net_loss_trend,
  AVG(daily_net_loss) OVER (PARTITION BY cc_state ORDER BY return_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
  DENSE_RANK() OVER (PARTITION BY cc_state ORDER BY daily_net_loss DESC) AS loss_dense_rank_state
FROM daily_stats
WHERE daily_return_cnt >= 10
ORDER BY cc_state, return_date
