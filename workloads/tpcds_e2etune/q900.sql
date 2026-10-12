WITH hd_agg AS (
  SELECT
    hd_income_band_sk,
    hd_vehicle_count,
    AVG(hd_dep_count) AS avg_dep,
    COUNT(*) AS hd_cnt
  FROM household_demographics
  WHERE hd_buy_potential = '1001-5000'
  GROUP BY hd_income_band_sk, hd_vehicle_count
),
item_agg AS (
  SELECT
    i_category_id,
    i_category,
    AVG(i_current_price) AS avg_price,
    COUNT(*) AS item_cnt
  FROM item
  WHERE i_units = 'Cup'
  GROUP BY i_category_id, i_category
),
time_agg AS (
  SELECT
    t_shift,
    t_meal_time,
    COUNT(*) AS time_cnt,
    AVG(t_hour) AS avg_hour
  FROM time_dim
  WHERE t_am_pm = 'PM'
  GROUP BY t_shift, t_meal_time
)
SELECT
  hd.hd_income_band_sk,
  hd.hd_vehicle_count,
  hd.avg_dep,
  hd.hd_cnt,
  i.i_category_id,
  i.i_category,
  i.avg_price,
  i.item_cnt,
  t.t_shift,
  t.t_meal_time,
  t.time_cnt,
  t.avg_hour,
  (hd.avg_dep * i.avg_price) AS weighted_metric
FROM hd_agg hd
JOIN item_agg i
  ON hd.hd_income_band_sk = i.i_category_id
JOIN time_agg t
  ON t.t_shift = CASE WHEN hd.hd_vehicle_count > 2 THEN 'Evening' ELSE 'Morning' END
WHERE hd.hd_cnt > 10
ORDER BY weighted_metric DESC
LIMIT 100
