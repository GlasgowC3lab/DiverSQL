SELECT d.d_year, i.i_category, SUM(cs.cs_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year, i.i_category
ORDER BY total_sales DESC
LIMIT 10
