WITH year_stats AS (
  SELECT d.d_year,
         r.r_reason_desc,
         COUNT(*) AS day_cnt,
         SUM(CASE WHEN d.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_cnt,
         AVG(d.d_dow) AS avg_dow
  FROM date_dim d
  JOIN reason r
    ON d.d_year = r.r_reason_sk
  WHERE d.d_date BETWEEN DATE '1900-01-01' AND DATE '1900-12-31'
  GROUP BY d.d_year, r.r_reason_desc
  HAVING COUNT(*) > 0
)
SELECT y.d_year,
       y.r_reason_desc,
       y.day_cnt,
       y.weekend_cnt,
       y.avg_dow,
       RANK() OVER (ORDER BY y.day_cnt DESC) AS year_rank
FROM year_stats y
ORDER BY y.day_cnt DESC
LIMIT 100
