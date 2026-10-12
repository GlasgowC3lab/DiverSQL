SELECT COUNT(*) AS band_count,
       AVG(ib_lower_bound) AS avg_lower_bound
FROM tpcds.income_band
WHERE ib_lower_bound >= 50000
  AND ib_upper_bound <= 150000
