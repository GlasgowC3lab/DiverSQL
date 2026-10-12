WITH cc_full AS (
  SELECT
    cc.cc_call_center_id,
    d.d_date,
    d.d_day_name,
    d.d_date_sk
  FROM call_center cc
  FULL OUTER JOIN date_dim d
    ON cc.cc_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
),
ws_sample AS (
  SELECT
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_wholesale_cost,
    ws.ws_ext_sales_price,
    d.d_date,
    d.d_day_name,
    d.d_date_sk,
    ARRAY[CAST(ws.ws_quantity AS double), CAST(ws.ws_wholesale_cost AS double)] AS metrics
  FROM web_sales ws
  TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_day_name IN ('Saturday','Thursday')
)
SELECT
  combined.source,
  combined.id,
  combined.d_date,
  combined.day_name,
  combined.metric_name,
  combined.metric_value
FROM (
  SELECT
    'call_center' AS source,
    cc.cc_call_center_id AS id,
    cc.d_date,
    cc.d_day_name AS day_name,
    'total_sales' AS metric_name,
    (
      SELECT COALESCE(SUM(ws2.ws_ext_sales_price), 0)
      FROM web_sales ws2
      WHERE ws2.ws_sold_date_sk = cc.d_date_sk
    ) AS metric_value
  FROM cc_full cc
  WHERE cc.cc_call_center_id IS NOT NULL

  UNION ALL

  SELECT
    'web_sales' AS source,
    CAST(ws.ws_item_sk AS varchar) AS id,
    ws.d_date,
    ws.d_day_name AS day_name,
    CASE unn.metric_pos
      WHEN 1 THEN 'quantity'
      ELSE 'wholesale_cost'
    END AS metric_name,
    CAST(unn.metric_value AS decimal(10,2)) AS metric_value
  FROM ws_sample ws
  CROSS JOIN UNNEST(ws.metrics) WITH ORDINALITY AS unn(metric_value, metric_pos)
) AS combined
ORDER BY combined.d_date DESC, combined.source, combined.metric_name
LIMIT 100
