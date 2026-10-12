SELECT td.t_sub_shift,
       SUM(sr.sr_return_amt) AS total_return_amount,
       COUNT(*) AS return_count
FROM store_returns sr
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
WHERE sr.sr_fee > 20.00
  AND td.t_time BETWEEN 12 AND 18
GROUP BY td.t_sub_shift
ORDER BY total_return_amount DESC
LIMIT 10
