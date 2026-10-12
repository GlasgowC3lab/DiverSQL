SELECT s.s_store_name, d.d_year, SUM(ss.ss_net_paid) AS total_sales
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY s.s_store_name, d.d_year
ORDER BY total_sales DESC
LIMIT 10
