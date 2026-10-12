SELECT
  d.d_year,
  i.i_category,
  sum(cs.cs_ext_sales_price) AS total_sales,
  sum(cs.cs_quantity) AS total_quantity
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, total_sales DESC
