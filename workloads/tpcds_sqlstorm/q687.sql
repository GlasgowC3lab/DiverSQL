SELECT s.s_store_name,
       SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
GROUP BY s.s_store_name
ORDER BY total_net_paid DESC
LIMIT 10
