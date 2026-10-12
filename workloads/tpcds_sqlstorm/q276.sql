SELECT s.s_state,
       d.d_year,
       d.d_month_seq,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 2000
GROUP BY s.s_state, d.d_year, d.d_month_seq
ORDER BY total_profit DESC
