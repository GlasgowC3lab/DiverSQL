WITH filtered AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics AS hd
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 0
      AND ib.ib_lower_bound >= 60000
      AND ib.ib_upper_bound <= 160000
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    COUNT(*) AS household_cnt,
    AVG(hd_vehicle_count) AS avg_vehicle_count
FROM filtered
GROUP BY ib_lower_bound, ib_upper_bound
ORDER BY household_cnt DESC
LIMIT 10
