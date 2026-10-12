SELECT d.d_date,
       i.inv_item_sk,
       SUM(i.inv_quantity_on_hand) AS total_quantity
FROM inventory i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
WHERE d.d_fy_year = 1907
  AND i.inv_warehouse_sk = 12
GROUP BY d.d_date, i.inv_item_sk
ORDER BY d.d_date
