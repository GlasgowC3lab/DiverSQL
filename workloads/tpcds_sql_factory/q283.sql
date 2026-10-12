WITH reason_loss AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        w.w_city,
        r.r_reason_desc,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_events,
        CASE
            WHEN SUM(cr.cr_net_loss) > 20000 THEN 'Very High'
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High'
            WHEN SUM(cr.cr_net_loss) > 5000 THEN 'Medium'
            ELSE 'Low'
        END AS loss_severity
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_state, w.w_city, r.r_reason_desc
)
SELECT
    w_warehouse_sk,
    w_state,
    w_city,
    r_reason_desc,
    total_return_qty,
    total_return_amt,
    total_net_loss,
    loss_severity,
    RANK() OVER (PARTITION BY w_warehouse_sk ORDER BY total_net_loss DESC) AS reason_rank_in_warehouse,
    DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS global_reason_dense_rank
FROM reason_loss
WHERE total_return_qty > 0
ORDER BY w_warehouse_sk, reason_rank_in_warehouse
