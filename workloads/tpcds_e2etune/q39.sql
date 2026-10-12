WITH shift_stats AS (
    SELECT
        t_shift,
        t_sub_shift,
        t_meal_time,
        t_am_pm,
        COUNT(*) AS total_records,
        AVG(t_hour) AS avg_hour,
        approx_percentile(t_hour, 0.5) AS median_hour,
        SUM(CASE WHEN t_hour BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS morning_count,
        SUM(CASE WHEN t_hour BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS afternoon_count,
        SUM(CASE WHEN t_hour BETWEEN 18 AND 23 THEN 1 ELSE 0 END) AS evening_count
    FROM time_dim
    WHERE t_minute IN (0, 1, 2, 3, 4)
      AND t_second IN (0, 1, 2, 3, 4)
    GROUP BY t_shift, t_sub_shift, t_meal_time, t_am_pm
    HAVING COUNT(*) > 10
)
SELECT
    t_shift,
    t_sub_shift,
    t_meal_time,
    t_am_pm,
    total_records,
    avg_hour,
    median_hour,
    morning_count,
    afternoon_count,
    evening_count,
    ROW_NUMBER() OVER (PARTITION BY t_shift ORDER BY total_records DESC) AS rank_within_shift
FROM shift_stats
ORDER BY total_records DESC, t_shift
