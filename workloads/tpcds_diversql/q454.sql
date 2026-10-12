WITH base_full AS (
  SELECT
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand,
    itm.i_category_id,
    itm.i_class,
    itm.i_manufact,
    itm.i_current_price,
    itm.i_rec_end_date
  FROM inventory inv
  FULL OUTER JOIN item itm
    ON inv.inv_item_sk = itm.i_item_sk
  WHERE
    itm.i_rec_end_date > DATE '1999-01-01'               -- predicate 1
    AND itm.i_manufact LIKE '%bar%'                     -- predicate 2
    AND itm.i_class <> 'toddlers'                       -- predicate 3
    AND inv.inv_quantity_on_hand >= 600                -- predicate 4
    AND inv.inv_warehouse_sk IN (1, 3, 5, 10)           -- predicate 5
),

agg_warehouse AS (
  SELECT
    inv_warehouse_sk,
    SUM(inv_quantity_on_hand) AS total_qty,
    AVG(i_current_price) AS avg_price
  FROM base_full
  WHERE inv_warehouse_sk IS NOT NULL
  GROUP BY inv_warehouse_sk
),

agg_category AS (
  SELECT
    i_category_id,
    SUM(inv_quantity_on_hand) AS total_qty,
    AVG(i_current_price) AS avg_price
  FROM base_full
  WHERE i_category_id IS NOT NULL
  GROUP BY i_category_id
),

union_agg AS (
  SELECT
    CAST(inv_warehouse_sk AS INTEGER) AS key,
    total_qty,
    avg_price
  FROM agg_warehouse
  UNION
  SELECT
    i_category_id AS key,
    total_qty,
    avg_price
  FROM agg_category
),

intersect_keys AS (
  SELECT i_item_sk FROM item WHERE i_rec_end_date > DATE '2000-01-01'
  INTERSECT
  SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 700
),

except_keys AS (
  SELECT inv_item_sk FROM inventory
  EXCEPT
  SELECT i_item_sk FROM item WHERE i_manufact LIKE '%callyeingeing%'
),

final_agg AS (
  SELECT
    key,
    SUM(total_qty) AS sum_qty,
    AVG(avg_price) AS avg_of_avg_price
  FROM union_agg
  WHERE key IN (SELECT * FROM intersect_keys)
    AND key NOT IN (SELECT * FROM except_keys)
  GROUP BY key
  HAVING SUM(total_qty) > 1000
)

SELECT
  key,
  sum_qty,
  avg_of_avg_price,
  (SELECT COUNT(*) FROM inventory) AS total_inventory_rows
FROM final_agg
WHERE EXISTS (
  SELECT 1 FROM item itm WHERE itm.i_category_id = final_agg.key
)
ORDER BY sum_qty DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
