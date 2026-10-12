WITH inv_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    GROUP BY inv_date_sk
),
wr_agg AS (
    SELECT
        wr_returned_date_sk,
        SUM(wr_return_quantity) AS total_return_qty,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_return_tax,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_fee) AS avg_fee,
        COUNT(DISTINCT wr_order_number) AS distinct_orders,
        COUNT(DISTINCT wr_item_sk) AS distinct_items_returned
    FROM web_returns
    GROUP BY wr_returned_date_sk
),
store_agg AS (
    SELECT
        s_closed_date_sk,
        COUNT(*) AS stores_closed,
        AVG(s_floor_space) AS avg_floor_space,
        SUM(s_number_employees) AS total_employees
    FROM store
    GROUP BY s_closed_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_current_quarter,
    COALESCE(i.total_inventory_qty, 0)          AS total_inventory_qty,
    COALESCE(i.distinct_items, 0)               AS distinct_inventory_items,
    COALESCE(w.total_return_qty, 0)             AS total_return_qty,
    COALESCE(w.total_return_amt, 0)             AS total_return_amt,
    COALESCE(w.total_return_tax, 0)             AS total_return_tax,
    COALESCE(w.total_net_loss, 0)               AS total_net_loss,
    COALESCE(w.avg_fee, 0)                      AS avg_fee_per_return,
    COALESCE(w.distinct_orders, 0)              AS distinct_orders,
    COALESCE(w.distinct_items_returned, 0)      AS distinct_items_returned,
    COALESCE(s.stores_closed, 0)                AS stores_closed,
    COALESCE(s.avg_floor_space, 0)              AS avg_store_floor_space,
    COALESCE(s.total_employees, 0)              AS total_store_employees,
    CASE
        WHEN COALESCE(i.total_inventory_qty, 0) = 0 THEN NULL
        ELSE COALESCE(w.total_return_amt, 0) / COALESCE(i.total_inventory_qty, 0)
    END                                         AS return_amt_per_inventory_qty,
    SUM(COALESCE(w.total_return_amt, 0)) OVER (
        PARTITION BY d.d_year
        ORDER BY d.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                           AS cumulative_return_amt_year,
    DENSE_RANK() OVER (
        PARTITION BY d.d_year
        ORDER BY COALESCE(w.total_return_amt, 0) DESC
    )                                           AS return_amt_rank_year
FROM date_dim d
LEFT JOIN inv_agg i   ON i.inv_date_sk   = d.d_date_sk
LEFT JOIN wr_agg w    ON w.wr_returned_date_sk = d.d_date_sk
LEFT JOIN store_agg s ON s.s_closed_date_sk    = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
ORDER BY d.d_date
