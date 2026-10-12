WITH inv_stats AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_quantity,
        AVG(inv_quantity_on_hand) AS avg_inventory_quantity
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    COUNT(DISTINCT cr.cr_order_number) AS num_return_orders,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_net_loss) AS total_net_loss,
    inv_stats.total_inventory_quantity,
    ROUND(SUM(cr.cr_return_quantity) / NULLIF(inv_stats.avg_inventory_quantity, 0), 2) AS return_to_avg_inventory_ratio,
    MIN(cr.cr_returned_date_sk) AS earliest_return_date,
    MAX(cr.cr_returned_date_sk) AS latest_return_date
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inv_stats
    ON inv_stats.inv_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_returned_date_sk BETWEEN 2451010 AND 2451100
    AND cr.cr_net_loss > 200
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    inv_stats.total_inventory_quantity,
    inv_stats.avg_inventory_quantity
HAVING SUM(cr.cr_return_quantity) > 100
ORDER BY total_net_loss DESC
LIMIT 100
