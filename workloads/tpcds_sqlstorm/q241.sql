SELECT d.d_year, s.s_store_name, SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 1998
GROUP BY d.d_year, s.s_store_name
ORDER BY total_net_paid DESC
LIMIT 10
