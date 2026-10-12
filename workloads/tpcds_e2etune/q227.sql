WITH agg AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        AVG(i.inv_quantity_on_hand) AS avg_qty,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS days_count
    FROM
        inventory i
    JOIN
        time_dim t
        ON i.inv_date_sk = t.t_time_sk
    WHERE
        i.inv_item_sk IN (1, 2, 4)
        AND i.inv_quantity_on_hand > 200
        AND t.t_sub_shift = 'morning'
        AND t.t_minute BETWEEN 0 AND 4
    GROUP BY
        i.inv_warehouse_sk,
        i.inv_item_sk
    HAVING
        COUNT(*) >= 2
)
SELECT
    inv_warehouse_sk,
    inv_item_sk,
    avg_qty,
    total_qty,
    days_count,
    RANK() OVER (ORDER BY avg_qty DESC) AS warehouse_item_rank
FROM
    agg
ORDER BY
    avg_qty DESC
LIMIT 10
