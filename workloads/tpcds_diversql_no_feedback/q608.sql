SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS demo_count,
    AVG(hd.hd_dep_count) AS avg_dep_count
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 100000
  AND hd.hd_buy_potential = '>10000'
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY ib.ib_lower_bound
