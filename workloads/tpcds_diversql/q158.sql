WITH first_set AS (
  SELECT i.inv_item_sk,
         w.w_warehouse_name,
         i.inv_quantity_on_hand
  FROM tpcds.inventory i
  JOIN tpcds.warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_gmt_offset = -6.00
    AND i.inv_quantity_on_hand > 0
),
second_set AS (
  SELECT i.inv_item_sk,
         w.w_warehouse_name,
         i.inv_quantity_on_hand
  FROM tpcds.inventory i
  JOIN tpcds.warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_warehouse_sq_ft > 600000
    AND i.inv_quantity_on_hand > 0
)
SELECT
  row_number() OVER (ORDER BY inv_item_sk) AS row_num,
  inv_item_sk,
  w_warehouse_name,
  inv_quantity_on_hand
FROM (
  SELECT inv_item_sk, w_warehouse_name, inv_quantity_on_hand FROM first_set
  INTERSECT
  SELECT inv_item_sk, w_warehouse_name, inv_quantity_on_hand FROM second_set
) AS intersected
ORDER BY inv_item_sk
