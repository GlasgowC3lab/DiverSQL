WITH hd_agg AS (
    SELECT
        hd_income_band_sk,
        hd_buy_potential,
        COUNT(*) AS household_cnt,
        AVG(hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd_dep_count) AS total_dep_cnt
    FROM household_demographics
    WHERE hd_vehicle_count > 0
      AND hd_dep_count <= 2
    GROUP BY hd_income_band_sk, hd_buy_potential
    HAVING COUNT(*) >= 5
)
SELECT
    ha.hd_income_band_sk,
    r.r_reason_desc,
    ha.hd_buy_potential,
    ha.household_cnt,
    ha.avg_vehicle_cnt,
    ha.total_dep_cnt,
    RANK() OVER (PARTITION BY ha.hd_buy_potential ORDER BY ha.avg_vehicle_cnt DESC) AS rank_in_potential
FROM hd_agg ha
JOIN reason r
    ON ha.hd_income_band_sk = r.r_reason_sk
WHERE r.r_reason_id LIKE 'AAAAAAA%'
ORDER BY ha.hd_buy_potential, rank_in_potential
LIMIT 10
