SELECT
  cc.cc_name AS call_center_name,
  cc.cc_market_manager,
  cp.cp_department AS catalog_department,
  cp.cp_catalog_number,
  s.s_store_id,
  s.s_state,
  d_ret.d_year AS return_year,
  COUNT(*) AS num_returns,
  SUM(sr.sr_return_amt) AS total_return_amount,
  SUM(sr.sr_net_loss) AS total_net_loss,
  AVG(sr.sr_return_quantity) AS avg_return_quantity,
  MAX(sr.sr_return_tax) AS max_return_tax
FROM store_returns sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
  ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_page cp
  ON cp.cp_end_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cp_start
  ON cp.cp_start_date_sk = d_cp_start.d_date_sk
WHERE d_ret.d_year = 2003
  AND cc.cc_market_manager IS NOT NULL
  AND cp.cp_type = 'primary'
GROUP BY
  cc.cc_name,
  cc.cc_market_manager,
  cp.cp_department,
  cp.cp_catalog_number,
  s.s_store_id,
  s.s_state,
  d_ret.d_year
ORDER BY total_return_amount DESC
LIMIT 100
