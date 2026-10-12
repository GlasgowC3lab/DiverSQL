SELECT r.r_reason_desc,
       SUM(cr.cr_return_amount) AS total_catalog_return_amount,
       SUM(sr.sr_return_amt) AS total_store_return_amount
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
WHERE cr.cr_returned_date_sk = 2450918
  AND sr.sr_returned_date_sk = 2452319
GROUP BY r.r_reason_desc
