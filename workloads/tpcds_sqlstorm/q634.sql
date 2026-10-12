SELECT s.s_store_name, SUM(ss.ss_net_paid) AS total_sales
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
GROUP BY s.s_store_name
ORDER BY total_sales DESC
LIMIT 10
