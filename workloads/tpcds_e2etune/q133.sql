WITH income_agg AS (
  SELECT 1 AS join_key,
         ib_income_band_sk,
         ib_upper_bound,
         ib_lower_bound,
         COUNT(*) AS band_count
  FROM income_band
  WHERE ib_income_band_sk BETWEEN 2 AND 4
  GROUP BY ib_income_band_sk, ib_upper_bound, ib_lower_bound
),
reason_agg AS (
  SELECT 1 AS join_key,
         r_reason_sk,
         r_reason_desc,
         COUNT(*) AS reason_count
  FROM reason
  WHERE r_reason_desc LIKE '%product%'
  GROUP BY r_reason_sk, r_reason_desc
),
ship_mode_agg AS (
  SELECT 1 AS join_key,
         sm_ship_mode_sk,
         sm_carrier,
         COUNT(*) AS ship_mode_count
  FROM ship_mode
  WHERE sm_carrier IS NOT NULL
  GROUP BY sm_ship_mode_sk, sm_carrier
),
warehouse_agg AS (
  SELECT 1 AS join_key,
         w_state,
         SUM(w_warehouse_sq_ft) AS total_sq_ft,
         COUNT(*) AS warehouse_count,
         AVG(w_warehouse_sq_ft) AS avg_sq_ft
  FROM warehouse
  WHERE w_country = 'United States'
  GROUP BY w_state
),
time_agg AS (
  SELECT 1 AS join_key,
         t_hour,
         COUNT(*) AS time_slot_count
  FROM time_dim
  WHERE t_hour BETWEEN 8 AND 17
  GROUP BY t_hour
)
SELECT
  w.w_state,
  w.total_sq_ft,
  w.warehouse_count,
  w.avg_sq_ft,
  r.r_reason_desc,
  r.reason_count,
  s.sm_carrier,
  s.ship_mode_count,
  i.ib_upper_bound,
  i.ib_lower_bound,
  i.band_count,
  t.t_hour,
  t.time_slot_count
FROM warehouse_agg w
JOIN reason_agg r ON w.join_key = r.join_key
JOIN ship_mode_agg s ON w.join_key = s.join_key
JOIN income_agg i ON w.join_key = i.join_key
JOIN time_agg t ON w.join_key = t.join_key
WHERE w.total_sq_ft > 100000
ORDER BY w.total_sq_ft DESC, r.reason_count DESC
LIMIT 100
