WITH sales_agg AS (
  SELECT
    cc.cc_state AS state,
    w.w_warehouse_id AS warehouse_id,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cc.cc_state IN ('TN', 'GA', 'MI')
    AND cc.cc_rec_end_date >= DATE '2000-12-31'
    AND cs.cs_sales_price > 50
  GROUP BY cc.cc_state, w.w_warehouse_id
),
inventory_agg AS (
  SELECT
    w.w_warehouse_id AS warehouse_id,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
  FROM inventory inv
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE inv.inv_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY w.w_warehouse_id
)
SELECT
  s.state,
  s.warehouse_id,
  s.total_net_profit,
  s.total_quantity_sold,
  i.total_inventory_qty,
  (s.total_net_profit / NULLIF(i.total_inventory_qty, 0)) AS profit_per_inventory,
  RANK() OVER (PARTITION BY s.state ORDER BY s.total_net_profit DESC) AS profit_rank_state
FROM sales_agg s
LEFT JOIN inventory_agg i ON s.warehouse_id = i.warehouse_id
WHERE s.total_net_profit > 0
ORDER BY s.state, profit_rank_state
