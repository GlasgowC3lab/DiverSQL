WITH sales_data AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_warehouse_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_ship_cdemo_sk,
    cs.cs_ext_ship_cost,
    cs.cs_net_paid_inc_ship,
    cs.cs_net_profit,
    cd.cd_purchase_estimate,
    cd.cd_dep_count,
    cd.cd_dep_college_count,
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_state,
    w.w_suite_number,
    w.w_street_name,
    inv.inv_quantity_on_hand
  FROM catalog_sales cs
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_ext_ship_cost > 500
    AND cs.cs_net_paid_inc_ship BETWEEN 1000 AND 8000
    AND cs.cs_ship_hdemo_sk IN (2319, 4563, 5455)
    AND cd.cd_purchase_estimate >= 2000
    AND cd.cd_dep_count <= 4
    AND w.w_state = 'CA'
    AND inv.inv_quantity_on_hand > 0
)
SELECT
  sd.cs_order_number,
  sd.cs_sold_date_sk,
  sd.w_warehouse_id,
  sd.w_warehouse_name,
  sd.w_suite_number,
  sd.w_street_name,
  sd.cs_ext_ship_cost,
  sd.cs_net_paid_inc_ship,
  sd.cs_net_profit,
  sd.cd_purchase_estimate,
  sd.cd_dep_count,
  sd.cd_dep_college_count,
  (
    SELECT SUM(inv2.inv_quantity_on_hand)
    FROM inventory inv2
    WHERE inv2.inv_warehouse_sk = sd.cs_warehouse_sk
  ) AS total_inventory_qty_for_warehouse,
  ROW_NUMBER() OVER (PARTITION BY sd.w_warehouse_id ORDER BY sd.cs_net_profit DESC) AS warehouse_profit_rank,
  RANK() OVER (PARTITION BY sd.w_state ORDER BY sd.cs_net_profit DESC) AS state_profit_rank
FROM sales_data sd
ORDER BY sd.cs_net_profit DESC
LIMIT 100
