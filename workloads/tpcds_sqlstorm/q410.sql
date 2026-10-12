SELECT d.d_year,
       SUM(ss.ss_net_paid) AS total_net_paid,
       COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY d.d_year
