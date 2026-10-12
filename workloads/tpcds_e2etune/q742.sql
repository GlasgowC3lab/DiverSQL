WITH inventory_item AS (
    SELECT inv.inv_date_sk,
           inv.inv_warehouse_sk,
           inv.inv_item_sk,
           inv.inv_quantity_on_hand,
           i.i_brand,
           i.i_brand_id,
           i.i_category,
           i.i_wholesale_cost,
           t.t_shift,
           t.t_am_pm,
           t.t_hour
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN time_dim t ON inv.inv_date_sk = t.t_time_sk
    WHERE i.i_brand_id IN (5003002, 1001001, 3002001)
      AND i.i_wholesale_cost BETWEEN 0.5 AND 10.0
      AND t.t_shift IS NOT NULL
),
brand_shift_agg AS (
    SELECT
        i_brand,
        t_shift,
        SUM(inv_quantity_on_hand) AS total_quantity,
        AVG(i_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory_item
    GROUP BY i_brand, t_shift
    HAVING SUM(inv_quantity_on_hand) > 500
)
SELECT
    i_brand,
    t_shift,
    total_quantity,
    avg_wholesale_cost,
    distinct_items,
    RANK() OVER (ORDER BY total_quantity DESC) AS brand_shift_rank
FROM brand_shift_agg
ORDER BY brand_shift_rank
LIMIT 10
