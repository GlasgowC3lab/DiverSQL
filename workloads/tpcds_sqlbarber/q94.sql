SELECT s.s_store_name,
       d.d_year,
       SUM(sr.sr_return_amt) AS total_return_amount,
       COUNT(sr.sr_ticket_number) AS return_count
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE d.d_year = 1922 AND s.s_state = 'GA'
GROUP BY s.s_store_name, d.d_year
