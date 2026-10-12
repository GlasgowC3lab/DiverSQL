WITH page_metrics AS (
  SELECT
    cp.cp_department,
    cp.cp_type,
    d_start.d_year AS start_year,
    COUNT(*) AS page_cnt,
    AVG(cp.cp_catalog_page_number) AS avg_page_num,
    AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_duration_days,
    SUM(cp.cp_catalog_page_number) AS total_page_number
  FROM catalog_page cp
  JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
  WHERE cp.cp_type IN ('quarterly', 'monthly')
    AND d_start.d_year = 2021
    AND d_end.d_date >= DATE '2021-12-01'
  GROUP BY cp.cp_department, cp.cp_type, d_start.d_year
  HAVING COUNT(*) > 5
)
SELECT
  cp_department,
  cp_type,
  start_year,
  page_cnt,
  avg_page_num,
  avg_duration_days,
  total_page_number,
  RANK() OVER (ORDER BY page_cnt DESC) AS dept_rank
FROM page_metrics
ORDER BY page_cnt DESC, cp_department
