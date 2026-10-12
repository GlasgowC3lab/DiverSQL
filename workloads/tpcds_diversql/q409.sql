WITH combined AS (
  SELECT
    sm.sm_carrier AS carrier,
    sm.sm_ship_mode_id AS ship_mode_id,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(ws.ws_net_paid) AS avg_net_paid,
    CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_flag,
    MIN(cs.cs_order_number) AS min_order_number
  FROM catalog_sales cs
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_carrier = 'FEDEX'
    AND cs.cs_wholesale_cost BETWEEN 20 AND 80
    AND cs.cs_quantity > 5
    AND ws.ws_coupon_amt < 2000
    AND cs.cs_ship_cdemo_sk = 775031
  GROUP BY sm.sm_carrier, sm.sm_ship_mode_id

  UNION

  SELECT
    sm.sm_carrier AS carrier,
    sm.sm_ship_mode_id AS ship_mode_id,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(ws.ws_net_paid) AS avg_net_paid,
    CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_flag,
    MIN(cs.cs_order_number) AS min_order_number
  FROM catalog_sales cs
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_carrier = 'GERMA'
    AND cs.cs_wholesale_cost > 50
    AND cs.cs_quantity <= 3
    AND ws.ws_coupon_amt > 3000
    AND cs.cs_ship_cdemo_sk = 1908318
  GROUP BY sm.sm_carrier, sm.sm_ship_mode_id
)
SELECT
  carrier,
  ship_mode_id,
  distinct_orders,
  total_profit,
  avg_net_paid,
  volume_flag,
  min_order_number
FROM combined
WHERE min_order_number NOT IN (
  SELECT ws_order_number
  FROM web_sales
  WHERE ws_coupon_amt > 5000
)
ORDER BY total_profit DESC
OFFSET 10 ROWS
LIMIT 100
