SELECT d.d_year,
       sum(cs.cs_ext_sales_price) AS total_sales,
       sum(cs.cs_ext_discount_amt) AS total_discount
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year
ORDER BY d.d_year
