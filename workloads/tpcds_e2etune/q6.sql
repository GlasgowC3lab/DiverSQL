WITH
    hd_agg AS (
        SELECT
            hd_buy_potential,
            hd_vehicle_count,
            COUNT(*) AS hh_cnt
        FROM household_demographics
        WHERE hd_vehicle_count > 0
          AND hd_income_band_sk IN (3, 4, 5)
        GROUP BY hd_buy_potential, hd_vehicle_count
    ),
    time_agg AS (
        SELECT
            t_shift,
            t_hour,
            COUNT(*) AS time_cnt
        FROM time_dim
        WHERE t_hour BETWEEN 6 AND 22
        GROUP BY t_shift, t_hour
    ),
    ship_agg AS (
        SELECT
            sm_contract,
            sm_carrier,
            COUNT(*) AS ship_cnt
        FROM ship_mode
        WHERE sm_contract IN ('YvxVaJI10', 'ldhM8IvpzHgdbBgDfI')
        GROUP BY sm_contract, sm_carrier
    ),
    joined_data AS (
        SELECT
            hd.hd_buy_potential,
            t.t_shift,
            s.sm_contract,
            hd.hh_cnt,
            hd.hd_vehicle_count
        FROM hd_agg hd
        JOIN time_agg t
            ON hd.hd_vehicle_count = t.t_hour
        JOIN ship_agg s
            ON s.sm_contract = CASE WHEN t.t_shift = 'Morning' THEN 'YvxVaJI10' ELSE 'ldhM8IvpzHgdbBgDfI' END
    ),
    aggregated AS (
        SELECT
            hd_buy_potential,
            t_shift,
            sm_contract,
            SUM(hh_cnt) AS total_households,
            AVG(hd_vehicle_count) AS avg_vehicles,
            COUNT(*) AS rows_in_group
        FROM joined_data
        GROUP BY hd_buy_potential, t_shift, sm_contract
    )
SELECT
    hd_buy_potential,
    t_shift,
    sm_contract,
    total_households,
    avg_vehicles,
    rows_in_group,
    COUNT(*) OVER (PARTITION BY hd_buy_potential) AS groups_per_buy_potential,
    ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY avg_vehicles DESC) AS vehicle_rank
FROM aggregated
ORDER BY total_households DESC
LIMIT 50
