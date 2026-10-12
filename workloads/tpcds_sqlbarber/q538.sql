SELECT r.r_reason_desc, SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_returned_date_sk = 2450996
GROUP BY r.r_reason_desc
