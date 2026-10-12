SELECT
  r.r_reason_desc,
  COUNT(*) AS return_cnt,
  SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns AS cr
JOIN reason AS r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_call_center_sk = 1
  AND r.r_reason_desc = 'Did not like the make'
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
