WITH base AS (
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM tpcds.household_demographics AS hd
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count >= 2
        AND hd.hd_vehicle_count <= 3
        AND hd.hd_buy_potential NOT IN ('Unknown')
        AND ib.ib_lower_bound >= 0
        AND ib.ib_upper_bound <= 100000
        AND hd.hd_income_band_sk IN (10, 11, 12, 19, 20)
),
agg_band AS (
    SELECT
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        COUNT(*) AS household_cnt,
        SUM(hd_dep_count) AS total_deps,
        AVG(hd_vehicle_count) AS avg_vehicles
    FROM base
    GROUP BY hd_income_band_sk, ib_lower_bound, ib_upper_bound
),
final_agg AS (
    SELECT
        AVG(total_deps) AS avg_total_deps,
        SUM(household_cnt) AS sum_households,
        AVG(avg_vehicles) AS avg_vehicles_across_bands
    FROM agg_band
    HAVING SUM(household_cnt) > 10
),
 dim AS (
    SELECT *
    FROM (VALUES
        ('Low Income'),
        ('Mid Income'),
        ('High Income')
    ) AS t(income_category)
)
SELECT
    d.income_category,
    f.avg_total_deps,
    f.sum_households,
    f.avg_vehicles_across_bands
FROM dim d
CROSS JOIN final_agg f
ORDER BY f.sum_households DESC
LIMIT 100
