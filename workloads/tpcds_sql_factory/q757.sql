WITH reason_city_agg AS (
  SELECT
    cc.cc_city,
    r.r_reason_desc,
    hd_ret.hd_vehicle_count,
    SUM(cr.cr_return_amount) AS sum_return_amt,
    COUNT(*) AS cnt_returns,
    SUM(cr.cr_return_quantity) AS total_quantity
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  GROUP BY cc.cc_city, r.r_reason_desc, hd_ret.hd_vehicle_count
)
SELECT
  cc_city,
  r_reason_desc,
  hd_vehicle_count,
  sum_return_amt,
  cnt_returns,
  total_quantity,
  RANK() OVER (PARTITION BY cc_city ORDER BY sum_return_amt DESC) AS reason_rank_in_city,
  SUM(sum_return_amt) OVER (PARTITION BY cc_city ORDER BY sum_return_amt DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt,
  DENSE_RANK() OVER (ORDER BY sum_return_amt DESC) AS global_return_dense_rank
FROM reason_city_agg
WHERE cnt_returns >= 5
ORDER BY cc_city, reason_rank_in_city
