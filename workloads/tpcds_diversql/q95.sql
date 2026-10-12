WITH
store_ret AS (
  SELECT
    td.t_hour AS hour,
    'store_return' AS metric_type,
    SUM(sr.sr_return_amt) AS total_amount
  FROM store_returns sr TABLESAMPLE BERNOULLI (10)
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  WHERE td.t_am_pm = 'PM'
    AND EXISTS (
      SELECT 1 FROM time_dim td2
      WHERE td2.t_time_id = td.t_time_id
        AND td2.t_am_pm = 'AM'
    )
  GROUP BY td.t_hour
),
web_sal AS (
  SELECT
    td.t_hour AS hour,
    'web_sale' AS metric_type,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_amount
  FROM web_sales ws TABLESAMPLE BERNOULLI (10)
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  WHERE ws.ws_wholesale_cost > 50
    AND td.t_am_pm = 'AM'
  GROUP BY td.t_hour
),
combined AS (
  SELECT
    hour,
    metric_type,
    total_amount,
    SUM(total_amount) OVER (PARTITION BY metric_type ORDER BY hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
  FROM store_ret
  UNION ALL
  SELECT
    hour,
    metric_type,
    total_amount,
    SUM(total_amount) OVER (PARTITION BY metric_type ORDER BY hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
  FROM web_sal
)
SELECT hour, metric_type, total_amount, running_total
FROM combined
ORDER BY metric_type, hour
LIMIT 100
