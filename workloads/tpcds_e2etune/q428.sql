WITH warehouse_totals AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_country,
        w.w_warehouse_sq_ft,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        AVG(i.inv_quantity_on_hand) AS avg_quantity_per_item
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_date_sk BETWEEN 2450800 AND 2451100
      AND w.w_country = 'United States'
      AND i.inv_quantity_on_hand > 0
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_country,
        w.w_warehouse_sq_ft
    HAVING SUM(i.inv_quantity_on_hand) > 500
)
SELECT
    wt.w_warehouse_id,
    wt.w_city,
    wt.w_country,
    wt.total_quantity,
    wt.distinct_items,
    wt.avg_quantity_per_item,
    ROUND(wt.total_quantity * 1.0 / wt.w_warehouse_sq_ft, 4) AS quantity_per_sqft,
    RANK() OVER (ORDER BY wt.total_quantity DESC) AS warehouse_quantity_rank
FROM warehouse_totals wt
ORDER BY wt.total_quantity DESC
LIMIT 10
