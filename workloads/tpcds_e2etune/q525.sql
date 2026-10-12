WITH agg AS (
    SELECT
        s.s_state AS state,
        s.s_city AS city,
        sm.sm_type AS ship_type,
        sm.sm_carrier AS carrier,
        COUNT(DISTINCT s.s_store_sk) AS store_cnt,
        AVG(s.s_floor_space) AS avg_floor_space,
        SUM(s.s_number_employees) AS total_employees,
        SUM(CASE WHEN sm.sm_type = 'EXPRESS' THEN s.s_floor_space ELSE 0 END) AS express_floor_space,
        SUM(CASE WHEN sm.sm_type = 'OVERNIGHT' THEN s.s_floor_space ELSE 0 END) AS overnight_floor_space
    FROM store s
    JOIN ship_mode sm ON TRUE
    WHERE s.s_state IN ('CA', 'TX', 'NY')
      AND s.s_closed_date_sk IS NULL
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT', 'TWO DAY')
    GROUP BY s.s_state, s.s_city, sm.sm_type, sm.sm_carrier
    HAVING COUNT(DISTINCT s.s_store_sk) >= 3
)
SELECT
    state,
    city,
    ship_type,
    carrier,
    store_cnt,
    avg_floor_space,
    total_employees,
    express_floor_space,
    overnight_floor_space,
    RANK() OVER (PARTITION BY state ORDER BY avg_floor_space DESC) AS floor_space_rank_state,
    ROW_NUMBER() OVER (PARTITION BY state, city ORDER BY store_cnt DESC) AS store_cnt_rn_city
FROM agg
ORDER BY state, floor_space_rank_state
LIMIT 200
