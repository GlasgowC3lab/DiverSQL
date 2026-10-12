SELECT
  inv.inv_warehouse_sk,
  i.i_brand,
  i.i_category,
  SUM(inv.inv_quantity_on_hand) AS total_qty,
  SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_inventory_value,
  AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
  RANK() OVER (PARTITION BY inv.inv_warehouse_sk ORDER BY SUM(inv.inv_quantity_on_hand * i.i_current_price) DESC) AS brand_rank
FROM
  inventory inv
JOIN
  item i
  ON inv.inv_item_sk = i.i_item_sk
WHERE
  i.i_category IN ('Electronics', 'Furniture')
  AND inv.inv_date_sk BETWEEN 20230101 AND 20231231
  AND inv.inv_quantity_on_hand > 0
GROUP BY
  inv.inv_warehouse_sk,
  i.i_brand,
  i.i_category
HAVING
  SUM(inv.inv_quantity_on_hand) > 1000
ORDER BY
  inv.inv_warehouse_sk,
  brand_rank
LIMIT 100
