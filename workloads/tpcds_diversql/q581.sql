WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand)          AS total_qty,
        MAX(inv_date_sk)                  AS latest_date_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0                              -- predicate 1
      AND inv_warehouse_sk IN (1, 3, 7, 14)                       -- predicate 2
      AND inv_item_sk IN (101420, 101425, 101437)                -- predicate 3
      AND inv_date_sk BETWEEN 2450800 AND 2451100                -- predicate 4
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    addr.full_address,
    i.i_category,
    i.i_class,
    agg.total_qty,
    agg.latest_date_sk,
    AVG(i.i_current_price)                                 AS avg_price,
    COUNT(DISTINCT i.i_item_sk)                           AS distinct_items,
    (
        SELECT MAX(i2.i_current_price)
        FROM   item i2
        WHERE  i2.i_category = i.i_category
    )                                                     AS max_price_in_category
FROM inv_agg agg
JOIN item i
  ON agg.inv_item_sk = i.i_item_sk
JOIN warehouse w
  ON agg.inv_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT CONCAT(w.w_street_number, ' ', w.w_street_name, ' ', w.w_street_type) AS full_address
) AS addr
WHERE i.i_category_id = 5                                 -- predicate 5
  AND i.i_brand_id = 12                                    -- predicate 6
  AND i.i_manufact_id = 338                                -- predicate 7
  AND i.i_current_price BETWEEN 10.00 AND 200.00           -- predicate 8
  AND w.w_state = 'CA'                                     -- predicate 9
  AND w.w_city LIKE 'San%'                                 -- predicate 10
  AND EXISTS (
        SELECT 1
        FROM   inventory inv2
        WHERE  inv2.inv_item_sk = agg.inv_item_sk
          AND  inv2.inv_warehouse_sk = agg.inv_warehouse_sk
          AND  inv2.inv_quantity_on_hand > 0
          AND  inv2.inv_date_sk = agg.latest_date_sk
      )
GROUP BY
    w.w_warehouse_id,
    w.w_city,
    addr.full_address,
    i.i_category,
    i.i_class,
    agg.total_qty,
    agg.latest_date_sk
ORDER BY agg.total_qty DESC, w.w_warehouse_id
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
