SELECT
  t_time_id,
  t_hour,
  t_minute,
  t_am_pm,
  COUNT(*) AS cnt
FROM tpcds.time_dim
WHERE t_hour BETWEEN 8 AND 10
  AND t_am_pm = 'AM'
GROUP BY t_time_id, t_hour, t_minute, t_am_pm
ORDER BY cnt DESC
LIMIT 10
