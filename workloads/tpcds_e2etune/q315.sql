SELECT
  cc.cc_manager,
  cc.cc_class,
  cc.cc_mkt_id,
  date_trunc('month', from_unixtime(cr.cr_returned_date_sk * 86400)) AS return_month,
  COUNT(*) AS total_returns,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_net_loss,
  AVG(cr.cr_return_amount) AS avg_return_amount,
  approx_percentile(cr.cr_return_amount, 0.5) AS median_return_amount,
  SUM(CASE WHEN cr.cr_return_amount > 1000 THEN 1 ELSE 0 END) AS high_value_returns
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_mkt_id = 3
  AND cc.cc_class = 'large'
  AND cr.cr_returned_date_sk BETWEEN 2450800 AND 2450900
GROUP BY
  cc.cc_manager,
  cc.cc_class,
  cc.cc_mkt_id,
  date_trunc('month', from_unixtime(cr.cr_returned_date_sk * 86400))
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
