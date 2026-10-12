SELECT i.i_category,
       d.d_year,
       SUM(cs.cs_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
GROUP BY i.i_category, d.d_year
ORDER BY total_sales DESC
LIMIT 10
