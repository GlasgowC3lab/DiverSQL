SELECT s.s_state,
       COUNT(*) AS closed_store_cnt
FROM store s
JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_quarter_name = '1902Q3'
GROUP BY s.s_state
ORDER BY closed_store_cnt DESC
