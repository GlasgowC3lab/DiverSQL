WITH hd_agg AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_demo_sk
    FROM household_demographics hd
    WHERE hd.hd_vehicle_count >= 1
      AND hd.hd_income_band_sk BETWEEN 2 AND 6
),
time_filtered AS (
    SELECT
        t_time_sk,
        t_meal_time,
        t_hour,
        t_shift
    FROM time_dim
    WHERE t_meal_time IN ('breakfast', 'lunch')
)
SELECT
    agg.hd_income_band_sk,
    agg.t_meal_time,
    agg.household_records,
    agg.total_vehicles,
    agg.avg_dependents,
    agg.unique_households,
    agg.ultra_high_buy_potential_cnt,
    RANK() OVER (PARTITION BY agg.t_meal_time ORDER BY agg.total_vehicles DESC) AS vehicle_rank
FROM (
    SELECT
        ha.hd_income_band_sk,
        tf.t_meal_time,
        COUNT(*) AS household_records,
        SUM(ha.hd_vehicle_count) AS total_vehicles,
        AVG(ha.hd_dep_count) AS avg_dependents,
        COUNT(DISTINCT ha.hd_demo_sk) AS unique_households,
        SUM(CASE WHEN ha.hd_buy_potential = '>10000' THEN 1 ELSE 0 END) AS ultra_high_buy_potential_cnt
    FROM hd_agg ha
    INNER JOIN time_filtered tf
        ON (ha.hd_demo_sk % 24) = (tf.t_time_sk % 24)
    GROUP BY ha.hd_income_band_sk, tf.t_meal_time
    HAVING COUNT(*) > 5
) agg
ORDER BY agg.t_meal_time, vehicle_rank
LIMIT 50
