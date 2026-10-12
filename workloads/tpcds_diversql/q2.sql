SELECT
  d_year,
  d_month_seq,
  COUNT(*) AS days_count
FROM tpcds.date_dim
WHERE d_current_month = 'Y'
  AND d_day_name = 'Monday'
  AND d_month_seq IN (4, 11)
GROUP BY d_year, d_month_seq
ORDER BY d_year DESC, d_month_seq
