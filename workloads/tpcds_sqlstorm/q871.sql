SELECT s.s_store_name,
       d.d_year,
       SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 2000
GROUP BY s.s_store_name, d.d_year
ORDER BY total_net_paid DESC
LIMIT 10
