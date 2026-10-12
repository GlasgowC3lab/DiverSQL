SELECT s.s_store_name,
       d.d_year,
       SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY s.s_store_name, d.d_year
ORDER BY total_profit DESC
LIMIT 10
