SELECT d.d_year, sum(s.ss_net_profit) AS total_profit
FROM store_sales s
JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY d.d_year
