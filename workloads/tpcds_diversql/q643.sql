SELECT r.r_reason_desc,
       SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
       AVG(sr.sr_return_tax) AS avg_return_tax,
       COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
FROM tpcds.store_returns sr
JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc = 'Gift exchange'
  AND sr.sr_return_tax > 5.00
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
