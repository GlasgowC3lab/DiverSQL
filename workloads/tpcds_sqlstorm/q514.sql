SELECT d.d_year,
       cc.cc_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(DISTINCT cs.cs_order_number) AS orders
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, cc.cc_name
ORDER BY total_sales DESC
LIMIT 100
