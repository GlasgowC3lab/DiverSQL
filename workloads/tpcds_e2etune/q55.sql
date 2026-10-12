WITH income_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        COUNT(*) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd.hd_dep_count) AS total_dependent_cnt,
        approx_percentile(hd.hd_vehicle_count, 0.5) AS median_vehicle_cnt
    FROM
        household_demographics hd
    JOIN
        income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        hd.hd_buy_potential IN ('501-1000', '1001-5000')
        AND hd.hd_vehicle_count > 0
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential
    HAVING
        COUNT(*) >= 5
)
SELECT
    ia.ib_income_band_sk,
    ia.ib_lower_bound,
    ia.ib_upper_bound,
    ia.hd_buy_potential,
    ia.household_cnt,
    ia.avg_vehicle_cnt,
    ia.total_dependent_cnt,
    ia.median_vehicle_cnt
FROM (
    SELECT
        ia.*,
        ROW_NUMBER() OVER (PARTITION BY ia.ib_income_band_sk ORDER BY ia.avg_vehicle_cnt DESC) AS rn
    FROM income_agg ia
) ia
WHERE rn = 1
ORDER BY ia.ib_lower_bound
