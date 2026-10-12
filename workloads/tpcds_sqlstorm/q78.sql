SELECT d.d_year,
       s.s_state,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt,
       AVG(ss.ss_quantity) AS avg_qty
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year, s.s_state
ORDER BY total_profit DESC
LIMIT 100
