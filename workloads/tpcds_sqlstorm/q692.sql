SELECT d.d_year, c.c_customer_id, SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, c.c_customer_id
ORDER BY total_profit DESC
LIMIT 100
