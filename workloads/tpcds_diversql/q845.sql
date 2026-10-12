WITH
  catalog_base AS (
    SELECT
      cr.cr_return_amount AS return_amount,
      cp.cp_department AS department,
      cd.cd_gender AS gender,
      cr.cr_warehouse_sk AS warehouse_sk,
      CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
      'Catalog' AS source
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  ),
  catalog_full AS (
    SELECT
      cb.department,
      cb.gender,
      cb.return_amount AS metric,
      cb.amount_category,
      cb.source
    FROM catalog_base cb
    FULL OUTER JOIN warehouse w ON cb.warehouse_sk = w.w_warehouse_sk
  ),
  web_base AS (
    SELECT
      ws.ws_net_profit AS net_profit,
      ws.ws_warehouse_sk AS warehouse_sk,
      cd.cd_gender AS gender,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS amount_category,
      'Web' AS source
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  ),
  web_full AS (
    SELECT
      NULL AS department,
      wb.gender,
      wb.net_profit AS metric,
      wb.amount_category,
      wb.source
    FROM web_base wb
    FULL OUTER JOIN warehouse w ON wb.warehouse_sk = w.w_warehouse_sk
  )
SELECT
  source,
  COALESCE(department, 'ALL') AS department,
  COALESCE(gender, 'ALL') AS gender,
  amount_category,
  SUM(metric) AS total_metric
FROM (
  SELECT * FROM catalog_full
  UNION ALL
  SELECT * FROM web_full
) u
GROUP BY ROLLUP (source, department, gender, amount_category)
ORDER BY source, department, gender, amount_category
LIMIT 100
