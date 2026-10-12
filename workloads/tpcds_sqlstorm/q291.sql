SELECT d.d_year,
       COUNT(*) AS order_cnt,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cs.cs_net_profit) AS total_net_profit
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year
ORDER BY d.d_year
