SELECT i.i_category,
       SUM(ss.ss_ext_sales_price) AS total_sales
FROM store_sales ss
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
GROUP BY i.i_category
ORDER BY total_sales DESC
LIMIT 10
