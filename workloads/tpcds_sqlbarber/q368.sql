SELECT cp.cp_department, d.d_year, SUM(cs.cs_net_paid) AS total_net_paid, AVG(cs.cs_ext_sales_price) AS avg_ext_sales_price
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 1903 AND cp.cp_department = 'DEPARTMENT'
GROUP BY cp.cp_department, d.d_year
ORDER BY total_net_paid DESC
LIMIT 100
