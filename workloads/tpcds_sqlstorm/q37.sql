SELECT d.d_year,
       COUNT(*) AS order_count,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year
ORDER BY d.d_year
