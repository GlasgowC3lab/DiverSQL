SELECT d.d_year,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(cs.cs_order_number) AS order_cnt
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year
ORDER BY d.d_year
