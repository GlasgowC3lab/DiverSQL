SELECT s.s_store_id, SUM(ss.ss_ext_sales_price) AS total_sales
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
GROUP BY s.s_store_id
ORDER BY total_sales DESC
LIMIT 5
