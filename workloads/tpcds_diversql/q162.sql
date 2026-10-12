WITH dim_set AS (
    SELECT w_state, sm_type, d_year
    FROM (
        SELECT w.w_state,
               sm.sm_type,
               d.d_year
        FROM catalog_returns cr
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE cr.cr_return_amount > 100
          AND d.d_year = 2000
        GROUP BY CUBE (w.w_state, sm.sm_type, d.d_year)
    )
    INTERSECT
    SELECT w_state, sm_type, d_year
    FROM (
        SELECT w.w_state,
               sm.sm_type,
               d.d_year
        FROM catalog_returns cr
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE cr.cr_return_amount > 500
          AND sm.sm_type = 'AIR'
          AND d.d_year = 2000
        GROUP BY CUBE (w.w_state, sm.sm_type, d.d_year)
    )
)
SELECT
    ds.w_state,
    ds.sm_type,
    ds.d_year,
    (
        SELECT SUM(i.inv_quantity_on_hand)
        FROM inventory i
        JOIN date_dim di ON i.inv_date_sk = di.d_date_sk
        JOIN warehouse w2 ON i.inv_warehouse_sk = w2.w_warehouse_sk
        WHERE di.d_year = ds.d_year
          AND w2.w_state = ds.w_state
    ) AS total_inventory_quantity
FROM dim_set ds
LIMIT 100
