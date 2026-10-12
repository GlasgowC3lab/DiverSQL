SELECT i.i_category, SUM(cs.cs_sales_price) AS total_sales
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
GROUP BY i.i_category
ORDER BY total_sales DESC
LIMIT 10
