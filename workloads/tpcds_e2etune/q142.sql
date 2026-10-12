WITH return_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        sm.sm_carrier,
        w.w_state,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_fee) AS total_fee
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_type = 'monthly' AND sm.sm_carrier LIKE 'Fed%'
    GROUP BY cp.cp_department, cp.cp_type, sm.sm_carrier, w.w_state
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    cp_department,
    cp_type,
    sm_carrier,
    w_state,
    return_cnt,
    total_quantity,
    total_return_amount,
    total_net_loss,
    avg_return_tax,
    total_fee,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM return_agg
ORDER BY total_return_amount DESC
LIMIT 50
