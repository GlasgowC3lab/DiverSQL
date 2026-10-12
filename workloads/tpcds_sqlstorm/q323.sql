SELECT d.d_year,
       s.s_state,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       AVG(ss.ss_ext_sales_price) AS avg_sales,
       COUNT(*) AS transaction_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, s.s_state
ORDER BY total_sales DESC
LIMIT 100
