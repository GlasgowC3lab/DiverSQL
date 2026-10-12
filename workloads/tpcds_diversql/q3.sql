SELECT i_category,
       COUNT(*) AS item_cnt,
       AVG(i_current_price) AS avg_price
FROM tpcds.item
WHERE i_wholesale_cost > 10.00
  AND i_class_id = 9
GROUP BY i_category
ORDER BY avg_price DESC
LIMIT 10
