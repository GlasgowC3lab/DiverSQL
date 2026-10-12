SELECT d.d_date, COUNT(*) AS sales_cnt
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
GROUP BY d.d_date
ORDER BY d.d_date
LIMIT 100
