SELECT d.d_year,
       COUNT(*) AS orders,
       SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY d.d_year
