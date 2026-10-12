SELECT d.d_year,
       COUNT(*) AS order_count,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       AVG(cs.cs_ext_sales_price) AS avg_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year
ORDER BY d.d_year
