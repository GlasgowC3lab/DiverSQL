SELECT d.d_year,
       d.d_month_seq,
       SUM(cs.cs_net_paid) AS total_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
