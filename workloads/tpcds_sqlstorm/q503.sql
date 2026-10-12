SELECT s.s_store_name,
       d.d_year,
       COUNT(*) AS sales_cnt,
       SUM(ss.ss_net_profit) AS net_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY s.s_store_name, d.d_year
ORDER BY net_profit DESC
LIMIT 10
