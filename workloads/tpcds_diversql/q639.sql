SELECT w.w_warehouse_name,
       i.inv_quantity_on_hand
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_warehouse_sk = 9
  AND w.w_zip = '74136'
  AND i.inv_item_sk = 101437
