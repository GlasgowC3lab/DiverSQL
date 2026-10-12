WITH state_agg AS (
    SELECT
        s_state,
        COUNT(*) AS store_cnt,
        SUM(s_floor_space) AS total_floor_space,
        AVG(s_number_employees) AS avg_employees,
        COUNT(DISTINCT s_manager) AS manager_cnt
    FROM store
    WHERE s_rec_end_date IS NULL OR s_rec_end_date > CURRENT_DATE
    GROUP BY s_state
),
manager_agg AS (
    SELECT
        s_state,
        s_manager,
        COUNT(*) AS stores_per_manager,
        SUM(s_floor_space) AS floor_space_per_manager
    FROM store
    WHERE s_rec_end_date IS NULL OR s_rec_end_date > CURRENT_DATE
    GROUP BY s_state, s_manager
)
SELECT
    s.s_state,
    s.store_cnt,
    s.total_floor_space,
    s.avg_employees,
    m.s_manager,
    m.stores_per_manager,
    CAST(m.stores_per_manager AS DOUBLE) / s.store_cnt AS manager_store_share,
    RANK() OVER (ORDER BY s.total_floor_space DESC) AS floor_space_rank
FROM state_agg s
JOIN manager_agg m
    ON s.s_state = m.s_state
WHERE s.total_floor_space > 50000
ORDER BY s.total_floor_space DESC, m.stores_per_manager DESC
LIMIT 100
