SELECT ib_income_band_sk,
       ib_lower_bound,
       ib_upper_bound
FROM tpcds.income_band
WHERE ib_upper_bound >= 100000
  AND ib_lower_bound <= 150000
ORDER BY ib_upper_bound DESC
LIMIT 10
