WITH band_stats AS (
  SELECT sm.sm_type,
         COUNT(*) AS band_count,
         AVG(ib.ib_upper_bound - ib.ib_lower_bound) AS avg_band_width,
         SUM(ib.ib_upper_bound - ib.ib_lower_bound) AS total_band_width
  FROM income_band ib
  CROSS JOIN ship_mode sm
  WHERE ib.ib_upper_bound >= 20000
    AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT', 'NEXT DAY')
  GROUP BY sm.sm_type
  HAVING COUNT(*) > 0
)
SELECT bs.sm_type,
       bs.band_count,
       bs.avg_band_width,
       bs.total_band_width,
       RANK() OVER (ORDER BY bs.total_band_width DESC) AS width_rank
FROM band_stats bs
ORDER BY width_rank
