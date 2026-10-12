SELECT d.d_year,
       COUNT(*) AS sales_count,
       SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year
ORDER BY d.d_year
