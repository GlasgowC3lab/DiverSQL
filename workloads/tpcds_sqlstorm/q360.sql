SELECT d.d_year,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(*) AS sales_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year
ORDER BY d.d_year
