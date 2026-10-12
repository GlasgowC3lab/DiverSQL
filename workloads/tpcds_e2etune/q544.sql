WITH hh_per_band AS (
    SELECT hd.hd_income_band_sk,
           COUNT(*) AS household_cnt,
           AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
           SUM(CASE WHEN hd.hd_buy_potential = '>10000' THEN 1 ELSE 0 END) AS high_buy_cnt,
           approx_percentile(hd.hd_dep_count, 0.5) AS median_dep_cnt
    FROM household_demographics hd
    GROUP BY hd.hd_income_band_sk
)
SELECT ib.ib_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       hhp.household_cnt,
       hhp.avg_vehicle_cnt,
       hhp.high_buy_cnt,
       hhp.median_dep_cnt,
       RANK() OVER (ORDER BY hhp.household_cnt DESC) AS household_rank
FROM income_band ib
JOIN hh_per_band hhp
  ON ib.ib_income_band_sk = hhp.hd_income_band_sk
WHERE ib.ib_lower_bound >= 20000
  AND hhp.avg_vehicle_cnt > 0
  AND hhp.household_cnt >= 5
ORDER BY hhp.household_cnt DESC
LIMIT 10
