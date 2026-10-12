WITH
  /* Catalog sales fact joined to all dimension tables */
  cs_joined AS (
    SELECT
      cs.cs_order_number               AS order_number,
      cs.cs_warehouse_sk               AS warehouse_sk,
      cs.cs_net_profit                 AS net_profit,
      cs.cs_ext_discount_amt           AS discount_amt,
      c.c_birth_day                    AS birth_day,
      ca.ca_address_sk                 AS address_sk,
      ca.ca_city                       AS address_city,
      sm.sm_ship_mode_id               AS ship_mode_id,
      w.w_warehouse_id                 AS warehouse_id,
      w.w_city                         AS warehouse_city,
      inv.inv_quantity_on_hand        AS qty_on_hand
    FROM catalog_sales cs
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv            ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE c.c_birth_day IN (15, 6, 9)
      AND cs.cs_ext_discount_amt > 10
      AND inv.inv_quantity_on_hand > 0
  ),

  /* Web sales fact joined to all dimension tables */
  ws_joined AS (
    SELECT
      ws.ws_order_number               AS order_number,
      ws.ws_warehouse_sk               AS warehouse_sk,
      ws.ws_net_profit                 AS net_profit,
      ws.ws_ext_discount_amt           AS discount_amt,
      c.c_birth_day                    AS birth_day,
      ca.ca_address_sk                 AS address_sk,
      ca.ca_city                       AS address_city,
      sm.sm_ship_mode_id               AS ship_mode_id,
      w.w_warehouse_id                 AS warehouse_id,
      w.w_city                         AS warehouse_city,
      inv.inv_quantity_on_hand        AS qty_on_hand
    FROM web_sales ws
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv            ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE c.c_birth_day IN (15, 6, 9)
      AND ws.ws_ext_discount_amt > 10
      AND inv.inv_quantity_on_hand > 0
  ),

  /* Orders that appear in BOTH facts */
  intersect_orders AS (
    SELECT order_number FROM cs_joined
    INTERSECT
    SELECT order_number FROM ws_joined
  ),

  /* Union of both fact streams */
  combined AS (
    SELECT * FROM cs_joined
    UNION ALL
    SELECT * FROM ws_joined
  ),

  /* Row‑level ranking inside each warehouse */
  ranked AS (
    SELECT
      warehouse_sk,
      net_profit,
      discount_amt,
      ROW_NUMBER() OVER (PARTITION BY warehouse_sk ORDER BY net_profit DESC) AS profit_rank,
      CASE WHEN discount_amt > 100 THEN 'High' ELSE 'Low' END AS discount_category
    FROM combined
  ),

  /* Aggregation with subtotals and grand total */
  aggregated AS (
    SELECT
      warehouse_sk,
      discount_category,
      SUM(net_profit)   AS sum_profit,
      SUM(discount_amt) AS sum_discount,
      COUNT(*)          AS txn_cnt
    FROM ranked
    GROUP BY ROLLUP (warehouse_sk, discount_category)
  )

SELECT
  a.warehouse_sk,
  w.w_warehouse_id,
  w.w_city AS warehouse_city,
  a.discount_category,
  a.sum_profit,
  a.sum_discount,
  a.txn_cnt,
  RANK() OVER (ORDER BY a.sum_profit DESC) AS overall_profit_rank
FROM aggregated a
LEFT JOIN warehouse w ON a.warehouse_sk = w.w_warehouse_sk
WHERE a.warehouse_sk IS NOT NULL
ORDER BY overall_profit_rank
LIMIT 100
