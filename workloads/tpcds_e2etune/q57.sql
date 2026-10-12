WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_warehouse_sk
),
returns_agg AS (
    SELECT
        cc.cc_state AS call_center_state,
        cc.cc_city AS call_center_city,
        sm.sm_type AS ship_mode_type,
        w.w_state AS warehouse_state,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(ia.total_inventory) AS total_inventory_on_hand
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg ia ON cr.cr_warehouse_sk = ia.inv_warehouse_sk
    WHERE cc.cc_state IN ('TN', 'GA')
      AND cr.cr_return_amount > 1000
    GROUP BY
        cc.cc_state,
        cc.cc_city,
        sm.sm_type,
        w.w_state
    HAVING SUM(cr.cr_return_amount) > 5000
)
SELECT
    call_center_state,
    call_center_city,
    ship_mode_type,
    warehouse_state,
    distinct_orders,
    total_return_amount,
    total_return_quantity,
    avg_return_amount,
    total_inventory_on_hand,
    ship_mode_rank
FROM (
    SELECT
        call_center_state,
        call_center_city,
        ship_mode_type,
        warehouse_state,
        distinct_orders,
        total_return_amount,
        total_return_quantity,
        avg_return_amount,
        total_inventory_on_hand,
        RANK() OVER (PARTITION BY call_center_state ORDER BY total_return_amount DESC) AS ship_mode_rank
    FROM returns_agg
) t
WHERE ship_mode_rank <= 5
ORDER BY total_return_amount DESC
LIMIT 200
