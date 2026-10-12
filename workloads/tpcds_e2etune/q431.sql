WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_city,
        w.w_state,
        w.w_country,
        w.w_warehouse_sq_ft,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        i.inv_date_sk
    FROM
        inventory i
    JOIN
        warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_state IN ('TN', 'LA', 'GA')
        AND i.inv_quantity_on_hand > 0
)
SELECT
    wi.w_city,
    wi.w_state,
    COUNT(DISTINCT wi.inv_item_sk) AS distinct_items,
    SUM(wi.inv_quantity_on_hand) AS total_quantity,
    AVG(wi.inv_quantity_on_hand) AS avg_quantity_per_item,
    ROW_NUMBER() OVER (ORDER BY SUM(wi.inv_quantity_on_hand) DESC) AS qty_rank
FROM
    warehouse_inventory wi
GROUP BY
    wi.w_city,
    wi.w_state
HAVING
    SUM(wi.inv_quantity_on_hand) > 1000
ORDER BY
    total_quantity DESC
LIMIT 20
