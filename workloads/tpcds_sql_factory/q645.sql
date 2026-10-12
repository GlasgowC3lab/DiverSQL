WITH warehouse_stats AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        w.w_state AS state,
        w.w_city AS city,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_fee) AS total_fee,
        AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
        COUNT(*) AS return_txn_count,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_state, w.w_city
)
SELECT
    warehouse_id,
    state,
    city,
    total_net_loss,
    total_fee,
    avg_ship_cost,
    return_txn_count,
    total_return_quantity,
    CASE
        WHEN total_net_loss > 2000 THEN 'HIGH_LOSS'
        WHEN total_net_loss > 500 THEN 'MEDIUM_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    PERCENT_RANK() OVER (PARTITION BY state ORDER BY total_net_loss) AS net_loss_percentile_state,
    NTILE(4) OVER (PARTITION BY state ORDER BY total_net_loss DESC) AS net_loss_quartile_state,
    RANK() OVER (ORDER BY total_fee DESC) AS fee_rank_global
FROM warehouse_stats
ORDER BY state, net_loss_percentile_state DESC
