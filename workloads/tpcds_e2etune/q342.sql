SELECT i.inv_warehouse_sk,
       sm.sm_carrier,
       i.inv_date_sk,
       SUM(ss.ss_quantity) AS total_quantity_sold,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_net_profit,
       AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
       SUM(ss.ss_quantity) * 1.0 / NULLIF(AVG(i.inv_quantity_on_hand), 0) AS sales_to_inventory_ratio
FROM inventory i
JOIN store_sales ss
  ON i.inv_item_sk = ss.ss_item_sk
 AND i.inv_date_sk = ss.ss_sold_date_sk
JOIN ship_mode sm
  ON (i.inv_warehouse_sk % 5) = sm.sm_ship_mode_sk
WHERE i.inv_date_sk BETWEEN 2450800 AND 2451100
  AND sm.sm_carrier IN ('UPS', 'FEDEX')
  AND i.inv_quantity_on_hand > 0
GROUP BY i.inv_warehouse_sk, sm.sm_carrier, i.inv_date_sk
HAVING SUM(ss.ss_quantity) > 0
ORDER BY total_net_profit DESC
LIMIT 50
