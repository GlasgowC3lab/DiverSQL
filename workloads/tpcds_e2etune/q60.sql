WITH closed_stores AS (
  SELECT s.s_state,
         s.s_floor_space,
         d.d_fy_quarter_seq,
         d.d_fy_year,
         CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END AS is_holiday
  FROM store s
  JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
  WHERE s.s_closed_date_sk IS NOT NULL
    AND d.d_fy_year BETWEEN 1900 AND 1904
),
agg AS (
  SELECT
    s_state,
    d_fy_year,
    d_fy_quarter_seq,
    COUNT(*) AS closed_store_cnt,
    AVG(s_floor_space) AS avg_floor_space,
    SUM(is_holiday) AS holiday_closed_cnt,
    ROUND(100.0 * SUM(is_holiday) / COUNT(*), 2) AS pct_holiday_closed
  FROM closed_stores
  GROUP BY s_state, d_fy_year, d_fy_quarter_seq
  HAVING COUNT(*) >= 5
)
SELECT
  s_state,
  d_fy_year,
  d_fy_quarter_seq,
  closed_store_cnt,
  avg_floor_space,
  holiday_closed_cnt,
  pct_holiday_closed,
  RANK() OVER (PARTITION BY d_fy_year ORDER BY avg_floor_space DESC) AS state_floor_space_rank
FROM agg
ORDER BY d_fy_year, d_fy_quarter_seq, state_floor_space_rank
LIMIT 200
