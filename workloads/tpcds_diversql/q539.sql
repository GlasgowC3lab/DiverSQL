WITH
  sampled_catalog AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_net_paid_inc_tax > 500
  ),
  ship_modes AS (
    SELECT *
    FROM ship_mode
    WHERE sm_contract LIKE 'H%'
  ),
  catalog_agg AS (
    SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
      COUNT(*) AS sales_cnt,
      CAST(NULL AS decimal(7,2)) AS avg_line_total
    FROM sampled_catalog cs
    JOIN ship_modes sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
  ),
  web_agg AS (
    SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      CASE WHEN SUM(ws.ws_ext_sales_price) > 200000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
      COUNT(*) AS sales_cnt,
      AVG(lt.line_total) AS avg_line_total
    FROM web_sales ws
    JOIN ship_modes sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    CROSS JOIN LATERAL (
      SELECT ws.ws_quantity * ws.ws_sales_price AS line_total
    ) lt
    WHERE ws.ws_net_paid_inc_tax BETWEEN 1000 AND 5000
    GROUP BY sm.sm_ship_mode_id
  ),
  unioned AS (
    SELECT ship_mode_id, total_sales, sales_level, sales_cnt, avg_line_total FROM catalog_agg
    UNION ALL
    SELECT ship_mode_id, total_sales, sales_level, sales_cnt, avg_line_total FROM web_agg
  )
SELECT
  COALESCE(u.ship_mode_id, sm.sm_ship_mode_id) AS ship_mode_id,
  sm.sm_contract,
  u.total_sales,
  u.sales_level,
  u.sales_cnt,
  u.avg_line_total,
  CASE WHEN u.total_sales IS NULL THEN 'NO_SALES' ELSE 'HAS_SALES' END AS sales_presence
FROM unioned u
FULL OUTER JOIN ship_modes sm ON u.ship_mode_id = sm.sm_ship_mode_id
ORDER BY u.total_sales DESC NULLS LAST
