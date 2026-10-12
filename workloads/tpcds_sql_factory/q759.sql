WITH state_income_stats AS (
  SELECT
    cc.cc_state,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    CASE WHEN hd.hd_income_band_sk >= 5 THEN 'HIGH_INCOME' ELSE 'LOW_INCOME' END AS income_category,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc NOT LIKE '%Cancelled%'
  GROUP BY cc.cc_state, hd.hd_income_band_sk, hd.hd_vehicle_count,
           CASE WHEN hd.hd_income_band_sk >= 5 THEN 'HIGH_INCOME' ELSE 'LOW_INCOME' END
)
SELECT
  cc_state,
  hd_income_band_sk,
  hd_vehicle_count,
  income_category,
  avg_return_amount,
  total_net_loss,
  total_returns,
  PERCENT_RANK() OVER (PARTITION BY cc_state ORDER BY avg_return_amount DESC) AS pct_rank_avg_return,
  RANK() OVER (ORDER BY total_net_loss DESC) AS overall_net_loss_rank
FROM state_income_stats
WHERE total_returns >= 10
ORDER BY cc_state, income_category, pct_rank_avg_return DESC
