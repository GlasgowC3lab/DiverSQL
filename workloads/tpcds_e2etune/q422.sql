SELECT s.s_state,
       d_closure.d_fy_year AS fiscal_year,
       COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_pages,
       SUM(date_diff('day', d_closure.d_date, d_end.d_date)) AS total_active_days,
       AVG(date_diff('day', d_closure.d_date, d_end.d_date)) AS avg_active_days,
       MAX(date_diff('day', d_closure.d_date, d_end.d_date)) AS max_active_days
FROM store s
JOIN date_dim d_closure
  ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_closure.d_date_sk
JOIN date_dim d_end
  ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE s.s_state IN ('CA', 'TX', 'NY')
  AND cp.cp_type = 'monthly'
  AND d_closure.d_fy_year = 2022
GROUP BY s.s_state, d_closure.d_fy_year
HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) > 5
ORDER BY total_active_days DESC
LIMIT 50
