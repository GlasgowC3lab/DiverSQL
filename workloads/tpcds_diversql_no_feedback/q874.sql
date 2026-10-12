WITH filtered AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM tpcds.household_demographics hd
    WHERE hd.hd_buy_potential IN ('501-1000', '1001-5000')
      AND hd.hd_dep_count BETWEEN 1 AND 4
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_vehicle_count <= 5
      AND hd.hd_demo_sk NOT IN (3, 9)
      AND hd.hd_income_band_sk IS NOT NULL
),
agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        COUNT(DISTINCT hd.hd_demo_sk) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicles,
        SUM(hd.hd_dep_count) AS total_deps,
        MIN(hd.hd_vehicle_count) AS min_vehicles,
        MAX(hd.hd_vehicle_count) AS max_vehicles
    FROM filtered hd
    RIGHT OUTER JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 40000
      AND ib.ib_upper_bound <= 200000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    household_cnt,
    avg_vehicles,
    total_deps,
    min_vehicles,
    max_vehicles,
    ROW_NUMBER() OVER (ORDER BY household_cnt DESC) AS row_num
FROM agg
ORDER BY household_cnt DESC
