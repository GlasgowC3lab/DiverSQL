SELECT
  td.t_am_pm,
  td.t_meal_time,
  COUNT(*) AS cnt
FROM tpcds.time_dim AS td
WHERE td.t_am_pm = 'PM'
  AND td.t_meal_time = 'dinner'
GROUP BY td.t_am_pm, td.t_meal_time
ORDER BY cnt DESC
LIMIT 10
