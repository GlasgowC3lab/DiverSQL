SELECT d.d_year,
       COUNT(*) AS order_cnt,
       SUM(ss.ss_net_paid) AS total_net_paid,
       AVG(ss.ss_quantity) AS avg_quantity
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year
ORDER BY d.d_year
