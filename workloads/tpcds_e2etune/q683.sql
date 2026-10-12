WITH store_ship_agg AS (
    SELECT
        s.s_state,
        sm.sm_carrier,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        AVG(s.s_floor_space) AS avg_floor_space,
        SUM(CASE WHEN sm.sm_type = 'EXPRESS' THEN 1 ELSE 0 END) AS express_mode_count,
        AVG(LENGTH(sm.sm_contract)) AS avg_contract_len
    FROM store s
    JOIN ship_mode sm ON 1 = 1
    WHERE s.s_rec_start_date >= DATE '2015-01-01'
      AND s.s_closed_date_sk IS NULL
      AND sm.sm_carrier IN ('UPS', 'FEDEX')
    GROUP BY s.s_state, sm.sm_carrier
    HAVING COUNT(DISTINCT s.s_store_sk) > 5
)
SELECT
    ssa.s_state,
    ssa.sm_carrier,
    ssa.store_count,
    ssa.avg_floor_space,
    ssa.express_mode_count,
    ssa.avg_contract_len,
    RANK() OVER (PARTITION BY ssa.s_state ORDER BY ssa.avg_floor_space DESC) AS floor_space_rank
FROM store_ship_agg ssa
ORDER BY ssa.s_state, floor_space_rank
LIMIT 100
