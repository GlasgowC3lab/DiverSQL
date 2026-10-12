SELECT
  r.r_reason_desc,
  COUNT(*) AS reason_count
FROM tpcds.reason AS r
WHERE r.r_reason_sk > 10
  AND r.r_reason_desc LIKE '%color%'
GROUP BY r.r_reason_desc
ORDER BY reason_count DESC
