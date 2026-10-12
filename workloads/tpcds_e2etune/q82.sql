WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_state
),
top_warehouses AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_state,
        total_net_loss,
        ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS rn
    FROM warehouse_returns
    WHERE total_returns >= 10
)
SELECT
    tw.w_warehouse_name,
    tw.w_state,
    sm.sm_type,
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
    SUM(cr.cr_net_loss) AS net_loss
FROM top_warehouses tw
JOIN catalog_returns cr ON cr.cr_warehouse_sk = tw.w_warehouse_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE tw.rn <= 10
GROUP BY tw.w_warehouse_name, tw.w_state, sm.sm_type, r.r_reason_desc
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY net_loss DESC
LIMIT 100
