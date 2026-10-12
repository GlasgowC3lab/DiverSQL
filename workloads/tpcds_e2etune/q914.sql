WITH inventory_agg AS (
    SELECT
        w.w_state,
        i.i_category,
        i.i_brand,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        AVG(i.i_current_price) AS avg_price
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_category IN ('Electronics', 'Furniture', 'Clothing')
      AND w.w_state IN ('CA', 'TX', 'NY')
      AND inv.inv_quantity_on_hand > 0
    GROUP BY w.w_state, i.i_category, i.i_brand
    HAVING SUM(inv.inv_quantity_on_hand) > 1000
)
SELECT
    w_state,
    i_category,
    i_brand,
    total_qty,
    avg_price,
    state_total_qty,
    CAST(total_qty AS DOUBLE) / NULLIF(state_total_qty, 0) AS inventory_ratio,
    RANK() OVER (PARTITION BY w_state ORDER BY total_qty DESC) AS category_rank
FROM (
    SELECT
        w_state,
        i_category,
        i_brand,
        total_qty,
        avg_price,
        SUM(total_qty) OVER (PARTITION BY w_state) AS state_total_qty
    FROM inventory_agg
) t
ORDER BY w_state, category_rank
LIMIT 50
