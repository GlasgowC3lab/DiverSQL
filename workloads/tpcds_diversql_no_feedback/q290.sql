WITH filtered_warehouses AS (
  SELECT
    w_warehouse_sk,
    w_warehouse_id,
    w_city,
    regexp_extract(w_warehouse_id, '(A{3,})', 1) AS id_pattern,
    substr(w_city, 1, 3)                AS city_prefix
  FROM warehouse
  WHERE regexp_like(w_warehouse_id, '^AAAA.*')
    AND w_city LIKE '%York%'
),

catalog_agg AS (
  SELECT
    fw.w_warehouse_id,
    fw.id_pattern,
    fw.city_prefix,
    hd.hd_demo_sk,
    SUM(cs.cs_net_profit)                         AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number)            AS distinct_orders
  FROM catalog_sales cs
  JOIN filtered_warehouses fw
    ON cs.cs_warehouse_sk = fw.w_warehouse_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cs.cs_bill_hdemo_sk IN (
          SELECT hd_demo_sk
          FROM household_demographics
          WHERE hd_vehicle_count > 2
        )
  GROUP BY fw.w_warehouse_id, fw.id_pattern, fw.city_prefix, hd.hd_demo_sk
),

web_returns_agg AS (
  SELECT
    fw.w_warehouse_id,
    fw.id_pattern,
    fw.city_prefix,
    hd.hd_demo_sk,
    SUM(wr.wr_net_loss)                         AS total_net_loss,
    COUNT(DISTINCT ws.ws_order_number)          AS distinct_ws_orders
  FROM web_returns wr
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
  JOIN filtered_warehouses fw
    ON ws.ws_warehouse_sk = fw.w_warehouse_sk
  JOIN household_demographics hd
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  GROUP BY fw.w_warehouse_id, fw.id_pattern, fw.city_prefix, hd.hd_demo_sk
)

SELECT
  ca.w_warehouse_id,
  ca.id_pattern,
  ca.city_prefix,
  ca.hd_demo_sk,
  ca.total_net_profit,
  COALESCE(wr.total_net_loss, 0)   AS total_net_loss,
  ca.distinct_orders,
  COALESCE(wr.distinct_ws_orders, 0) AS distinct_ws_orders
FROM catalog_agg ca
LEFT JOIN web_returns_agg wr
  ON ca.w_warehouse_id = wr.w_warehouse_id
 AND ca.id_pattern     = wr.id_pattern
 AND ca.city_prefix    = wr.city_prefix
 AND ca.hd_demo_sk     = wr.hd_demo_sk
ORDER BY ca.total_net_profit DESC
LIMIT 100
