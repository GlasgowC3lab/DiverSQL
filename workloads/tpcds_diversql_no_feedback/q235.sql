WITH catalog AS (
  SELECT
    cr_warehouse_sk,
    cr_return_amount,
    cr_return_tax,
    cr_net_loss,
    cr_reason_sk
  FROM catalog_returns
  WHERE cr_net_loss > 0
),
web AS (
  SELECT
    ws.ws_warehouse_sk AS warehouse_sk,
    wr.wr_return_amt AS return_amount,
    wr.wr_return_tax AS return_tax,
    wr.wr_net_loss AS net_loss,
    wr.wr_reason_sk AS reason_sk
  FROM web_returns wr
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
  WHERE wr.wr_net_loss > 0
),
combined AS (
  SELECT
    cr_warehouse_sk AS warehouse_sk,
    cr_return_amount + cr_return_tax AS total_return,
    cr_net_loss AS net_loss,
    cr_reason_sk AS reason_sk,
    'catalog' AS source
  FROM catalog
  UNION ALL
  SELECT
    warehouse_sk,
    return_amount + return_tax,
    net_loss,
    reason_sk,
    'web' AS source
  FROM web
)
SELECT
  w.w_warehouse_id,
  w.w_city,
  CASE
    WHEN SUM(c.total_return) > 10000 THEN 'HIGH'
    WHEN SUM(c.total_return) BETWEEN 5000 AND 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS return_volume_category,
  SUM(c.total_return) AS total_return_amount,
  SUM(c.net_loss) AS total_net_loss,
  COUNT(DISTINCT c.source) AS num_sources,
  regexp_extract(w.w_street_name, '(\\w+)$') AS street_suffix,
  CONCAT(w.w_city, ', ', w.w_state) AS location,
  CASE
    WHEN regexp_like(w.w_street_name, '^A') THEN 'StartsWithA'
    ELSE 'Other'
  END AS street_name_group
FROM combined c
JOIN warehouse w
  ON c.warehouse_sk = w.w_warehouse_sk
WHERE w.w_street_type LIKE '%e%'
GROUP BY
  w.w_warehouse_id,
  w.w_city,
  w.w_state,
  w.w_street_name
ORDER BY total_return_amount DESC
LIMIT 100
