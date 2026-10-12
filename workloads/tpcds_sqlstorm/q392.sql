SELECT s.s_state, d.d_year, SUM(ss.ss_net_paid) AS total_sales
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY s.s_state, d.d_year
ORDER BY total_sales DESC
LIMIT 100
