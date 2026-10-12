SELECT inv_warehouse_sk,
       SUM(inv_quantity_on_hand) AS total_quantity_on_hand
FROM tpcds.inventory
WHERE inv_date_sk BETWEEN 2450820 AND 2450900
  AND inv_warehouse_sk IN (4, 7)
GROUP BY inv_warehouse_sk
ORDER BY total_quantity_on_hand DESC
