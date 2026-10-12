WITH hd_ib AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM household_demographics hd
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(*) AS household_cnt,
    AVG(hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(CASE WHEN hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_buy_potential_cnt,
    SUM(CASE WHEN hd_buy_potential = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_buy_potential_cnt,
    SUM(CASE WHEN hd_buy_potential = 'LOW' THEN 1 ELSE 0 END) AS low_buy_potential_cnt,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rank_by_household_cnt,
    (SELECT AVG(s_tax_percentage) FROM store) AS avg_store_tax_percentage
FROM hd_ib
GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
HAVING COUNT(*) >= 5
ORDER BY household_cnt DESC
LIMIT 20
