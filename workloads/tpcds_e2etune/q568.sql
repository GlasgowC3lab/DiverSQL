WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_country,
        w.w_state,
        w.w_city,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        AVG(i.inv_quantity_on_hand) AS avg_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0
      AND w.w_gmt_offset BETWEEN -5.00 AND 2.00
      AND w.w_country = 'United States'
    GROUP BY w.w_warehouse_sk, w.w_country, w.w_state, w.w_city
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT
    w_country,
    w_state,
    w_city,
    total_qty,
    avg_qty,
    distinct_items,
    RANK() OVER (PARTITION BY w_state ORDER BY total_qty DESC) AS state_rank
FROM warehouse_inventory
ORDER BY total_qty DESC
LIMIT 50
