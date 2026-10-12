WITH ship_agg AS (
    SELECT
        sm_type,
        COUNT(*) AS ship_mode_count,
        COUNT(DISTINCT sm_carrier) AS distinct_carriers,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS sm_type_rank
    FROM ship_mode
    WHERE sm_code LIKE 'S%'
    GROUP BY sm_type
),
household_agg AS (
    SELECT
        hd_buy_potential,
        COUNT(*) AS total_households,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        SUM(CASE WHEN hd_vehicle_count > 0 THEN 1 ELSE 0 END) AS households_with_vehicles
    FROM household_demographics
    WHERE hd_dep_count >= 1
    GROUP BY hd_buy_potential
    HAVING AVG(hd_vehicle_count) > 0
)
SELECT
    h.hd_buy_potential,
    h.total_households,
    h.avg_vehicle_count,
    h.households_with_vehicles,
    s.sm_type,
    s.ship_mode_count,
    s.distinct_carriers,
    s.sm_type_rank
FROM household_agg h
JOIN ship_agg s ON true
WHERE s.sm_type_rank <= 5
ORDER BY h.avg_vehicle_count DESC, s.sm_type_rank ASC
LIMIT 50
