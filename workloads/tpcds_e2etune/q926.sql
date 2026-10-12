SELECT
  ca.ca_state AS state,
  cr.cr_ship_mode_sk AS ship_mode,
  COUNT(DISTINCT cr.cr_order_number) AS num_returns,
  SUM(cr.cr_return_quantity) AS total_return_qty,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_net_loss,
  SUM(cs.cs_net_profit) AS total_sales_profit,
  AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
JOIN customer_address ca
  ON cr.cr_returning_addr_sk = ca.ca_address_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = cr.cr_item_sk
  AND inv.inv_warehouse_sk = cr.cr_warehouse_sk
WHERE cr.cr_ship_mode_sk IN (7, 12)
  AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
GROUP BY ca.ca_state, cr.cr_ship_mode_sk
HAVING SUM(cr.cr_return_quantity) > 5
ORDER BY total_net_loss DESC
LIMIT 100
