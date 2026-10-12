WITH returns_agg AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 6 AND 22
      AND wr.wr_return_amt > 0
    GROUP BY t.t_hour, t.t_shift
    HAVING SUM(wr.wr_return_amt) > 500
),
inventory_agg AS (
    SELECT
        w.w_city,
        w.w_state,
        SUM(i.inv_quantity_on_hand) AS total_on_hand,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        AVG(i.inv_quantity_on_hand) AS avg_qty_per_item
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND i.inv_quantity_on_hand > 0
    GROUP BY w.w_city, w.w_state
)
SELECT *
FROM (
    SELECT
        r.t_hour,
        r.t_shift,
        i.w_city,
        i.w_state,
        r.total_return_amt,
        r.total_return_qty,
        r.avg_return_tax,
        i.total_on_hand,
        i.distinct_items,
        i.avg_qty_per_item,
        ROW_NUMBER() OVER (PARTITION BY i.w_city ORDER BY r.total_return_amt DESC) AS city_return_rank
    FROM returns_agg r
    JOIN inventory_agg i
        ON TRUE
) ranked
WHERE city_return_rank <= 5
ORDER BY w_city, total_return_amt DESC
LIMIT 200
