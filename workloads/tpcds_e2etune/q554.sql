WITH page_dates AS (
  SELECT
    cp.cp_department AS department,
    cp.cp_catalog_page_number,
    sd.d_fy_year AS start_fy_year,
    ed.d_fy_year AS end_fy_year,
    sd.d_date AS start_date,
    ed.d_date AS end_date,
    date_diff('day', sd.d_date, ed.d_date) AS duration_days
  FROM catalog_page cp
  JOIN date_dim sd ON cp.cp_start_date_sk = sd.d_date_sk
  JOIN date_dim ed ON cp.cp_end_date_sk = ed.d_date_sk
  WHERE cp.cp_department = 'DEPARTMENT'
    AND cp.cp_catalog_page_number IN (1, 2, 3, 5, 6)
    AND sd.d_year >= 2000
    AND ed.d_year <= 2025
),
aggregated AS (
  SELECT
    department,
    start_fy_year,
    COUNT(*) AS page_count,
    AVG(cp_catalog_page_number) AS avg_page_number,
    AVG(duration_days) AS avg_duration_days,
    MIN(cp_catalog_page_number) AS min_page_number,
    MAX(cp_catalog_page_number) AS max_page_number
  FROM page_dates
  GROUP BY department, start_fy_year
  HAVING COUNT(*) > 5
)
SELECT
  department,
  start_fy_year,
  page_count,
  avg_page_number,
  avg_duration_days,
  min_page_number,
  max_page_number,
  RANK() OVER (PARTITION BY start_fy_year ORDER BY page_count DESC) AS dept_rank
FROM aggregated
ORDER BY page_count DESC
LIMIT 100
