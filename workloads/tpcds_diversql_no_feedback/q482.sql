SELECT r_reason_id,
       r_reason_desc
FROM tpcds.reason
WHERE r_reason_sk IN (8, 12)
  AND r_reason_desc LIKE 'Did not%'
