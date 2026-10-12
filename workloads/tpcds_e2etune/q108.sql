SELECT
  w_warehouse_id,
  w_warehouse_name,
  total_inventory_value,
  avg_wholesale_cost,
  total_quantity,
  RANK() OVER (ORDER BY total_inventory_value DESC) AS warehouse_rank
FROM (
  SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    SUM(i.inv_quantity_on_hand * it.i_wholesale_cost) AS total_inventory_value,
    AVG(it.i_wholesale_cost) AS avg_wholesale_cost,
    SUM(i.inv_quantity_on_hand) AS total_quantity
  FROM inventory i
  JOIN item it ON i.inv_item_sk = it.i_item_sk
  JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE it.i_current_price > 50
    AND it.i_category = 'Electronics'
    AND w.w_state = 'CA'
  GROUP BY w.w_warehouse_id, w.w_warehouse_name
  HAVING SUM(i.inv_quantity_on_hand) > 1000
) t
ORDER BY total_inventory_value DESC
LIMIT 10
