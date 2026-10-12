WITH item_arrays AS (
    SELECT i_manufact_id,
           array_agg(i_item_id) AS item_ids
    FROM item
    WHERE i_wholesale_cost > 0
    GROUP BY i_manufact_id
),
unnested_items AS (
    SELECT i_manufact_id,
           item_id
    FROM item_arrays
    CROSS JOIN UNNEST(item_ids) AS t(item_id)
),
returns_agg AS (
    SELECT cr_item_sk,
           COUNT(*) AS return_cnt,
           SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amount > 10
      AND cr_reversed_charge < 500
      AND cr_returning_cdemo_sk IN (
          SELECT DISTINCT cr_returning_cdemo_sk
          FROM catalog_returns
          WHERE cr_return_quantity > 5
      )
    GROUP BY cr_item_sk
),
inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand,
           MAX(inv_warehouse_sk) AS warehouse_sk,
           MAX(inv_date_sk) AS date_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_warehouse_sk IN (2, 6, 9)
      AND inv_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY inv_item_sk
)
SELECT i.i_manufact_id,
       i.i_brand,
       r.return_cnt,
       r.total_return_amount,
       inv.total_on_hand,
       u.item_id,
       (r.return_cnt * mult.multiplier) AS scaled_return_cnt
FROM item i
JOIN returns_agg r
  ON i.i_item_sk = r.cr_item_sk
JOIN inv_agg inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN unnested_items u
  ON u.i_manufact_id = i.i_manufact_id
CROSS JOIN (VALUES (1), (2), (3)) AS mult(multiplier)
WHERE i.i_class IN ('dresses', 'pants', 'infants', 'pop', 'country')
  AND i.i_wholesale_cost BETWEEN 5 AND 30
  AND i.i_brand_id NOT IN (
      SELECT DISTINCT i_brand_id
      FROM item
      WHERE i_color = 'red'
  )
  AND i.i_manufact_id IN (
      SELECT i_manufact_id
      FROM item
      WHERE i_rec_start_date > DATE '2000-01-01'
  )
ORDER BY r.total_return_amount DESC,
         scaled_return_cnt ASC
LIMIT 100
