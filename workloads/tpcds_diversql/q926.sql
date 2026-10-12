WITH
  cr_agg AS (
    SELECT
      cr_returned_time_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS cnt_returns,
      AVG(cr_return_quantity) AS avg_qty
    FROM tpcds.catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_amount > 10
      AND cr_return_quantity >= 1
      AND cr_warehouse_sk IN (4, 5, 8, 12, 18)
      AND cr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND cr_fee < 5
    GROUP BY cr_returned_time_sk
  ),
  time_excluded AS (
    SELECT DISTINCT cr_returned_time_sk
    FROM tpcds.catalog_returns
    WHERE cr_return_amount < 5
    EXCEPT
    SELECT DISTINCT cr_returned_time_sk
    FROM tpcds.catalog_returns
    WHERE cr_return_quantity = 0
  ),
  union_agg AS (
    SELECT cr_returned_time_sk,
           total_return_amount
    FROM cr_agg
    UNION
    SELECT cr_returned_time_sk,
           SUM(cr_return_amount) AS total_return_amount
    FROM tpcds.catalog_returns
    WHERE cr_returned_time_sk IS NOT NULL
    GROUP BY cr_returned_time_sk
  )
SELECT
  td.t_meal_time,
  td.t_hour,
  SUM(ua.total_return_amount) AS sum_return_amount,
  COUNT(DISTINCT ua.cr_returned_time_sk) AS distinct_time_keys,
  AVG(ua.total_return_amount) AS avg_return_per_time
FROM union_agg ua
JOIN tpcds.time_dim td
  ON ua.cr_returned_time_sk = td.t_time_sk
WHERE td.t_meal_time IN ('breakfast', 'lunch', 'dinner')
  AND td.t_hour BETWEEN 8 AND 20
  AND td.t_shift = 'day'
  AND td.t_meal_time <> 'snack'
  AND td.t_am_pm = 'AM'
  AND ua.cr_returned_time_sk NOT IN (SELECT cr_returned_time_sk FROM time_excluded)
GROUP BY td.t_meal_time, td.t_hour
ORDER BY sum_return_amount DESC
LIMIT 100
