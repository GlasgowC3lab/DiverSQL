WITH hd_income AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics AS hd
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_dep_count <= 5
      AND ib.ib_upper_bound <= 100000
)
SELECT
    hd_income.hd_buy_potential,
    COUNT(DISTINCT hd_income.hd_demo_sk) AS household_count,
    AVG(hd_income.hd_dep_count) AS avg_dependents,
    MAX(hd_income.hd_vehicle_count) AS max_vehicles,
    MIN(hd_income.ib_lower_bound) AS min_income_lower,
    MAX(hd_income.ib_upper_bound) AS max_income_upper
FROM hd_income
GROUP BY hd_income.hd_buy_potential
ORDER BY household_count DESC, hd_income.hd_buy_potential
LIMIT 100
