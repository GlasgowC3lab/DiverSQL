SELECT
  ca.ca_state,
  ca.ca_country,
  COUNT(DISTINCT ca.ca_address_id) AS num_addresses,
  SUM(i.inv_quantity_on_hand) AS total_quantity,
  AVG(i.inv_quantity_on_hand) AS avg_quantity,
  COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
  MAX(sm.sm_contract) AS max_contract,
  COUNT(*) FILTER (WHERE sm.sm_type = 'AIR') AS air_shipments,
  COUNT(*) FILTER (WHERE sm.sm_type = 'GROUND') AS ground_shipments
FROM inventory i
JOIN ship_mode sm
  ON i.inv_warehouse_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
  ON i.inv_item_sk = ca.ca_address_sk
WHERE ca.ca_state IN ('AZ', 'CO', 'PA')
  AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
  AND i.inv_quantity_on_hand > 0
  AND sm.sm_contract LIKE 'C%'
GROUP BY ca.ca_state, ca.ca_country
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY total_quantity DESC, ca.ca_state
LIMIT 20
