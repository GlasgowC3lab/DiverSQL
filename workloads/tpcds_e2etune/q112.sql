WITH inventory_item AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_wholesale_cost,
        inv.inv_quantity_on_hand,
        i.i_item_sk
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50
      AND inv.inv_quantity_on_hand > 0
),
category_agg AS (
    SELECT
        i_category,
        i_brand,
        SUM(inv_quantity_on_hand) AS total_qty,
        AVG(i_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT i_item_sk) AS distinct_items
    FROM inventory_item
    GROUP BY i_category, i_brand
    HAVING SUM(inv_quantity_on_hand) > 1000
)
SELECT
    i_category,
    i_brand,
    total_qty,
    avg_wholesale_cost,
    distinct_items,
    ROUND(100.0 * total_qty / SUM(total_qty) OVER (), 2) AS pct_of_total_qty,
    RANK() OVER (ORDER BY total_qty DESC) AS qty_rank
FROM category_agg
ORDER BY total_qty DESC
LIMIT 10
