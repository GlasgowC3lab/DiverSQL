SELECT d.d_year,
       SUM(cs.cs_net_paid) AS total_sales,
       COUNT(*) AS total_orders
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY d.d_year
