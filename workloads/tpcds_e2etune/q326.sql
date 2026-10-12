WITH dept_stats AS (
  SELECT
    cp.cp_department,
    d_start.d_quarter_name,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_pages,
    AVG(cp.cp_catalog_number) AS avg_catalog_number,
    MIN(d_start.d_date) AS earliest_start,
    MAX(d_end.d_date) AS latest_end
  FROM catalog_page cp
  JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
  WHERE cp.cp_type = 'monthly'
    AND d_start.d_year = 2022
    AND d_end.d_year = 2022
    AND d_end.d_date >= d_start.d_date
  GROUP BY cp.cp_department, d_start.d_quarter_name
  HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) >= 2
)
SELECT
  cp_department,
  d_quarter_name,
  num_pages,
  avg_catalog_number,
  earliest_start,
  latest_end,
  RANK() OVER (ORDER BY num_pages DESC) AS dept_rank
FROM dept_stats
ORDER BY num_pages DESC
LIMIT 10
