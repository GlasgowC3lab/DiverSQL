SELECT cp.cp_department,
       sm.sm_carrier,
       SUM(inv.inv_quantity_on_hand) AS total_quantity,
       COUNT(DISTINCT ca.ca_address_sk) AS unique_customers,
       AVG(hd.hd_vehicle_count) AS avg_vehicle_count
FROM catalog_page cp
JOIN inventory inv
  ON inv.inv_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN ship_mode sm
  ON inv.inv_warehouse_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
  ON inv.inv_item_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON TRUE
WHERE cp.cp_type = 'monthly'
  AND sm.sm_carrier = 'UPS'
  AND ca.ca_country = 'United States'
GROUP BY cp.cp_department, sm.sm_carrier
HAVING SUM(inv.inv_quantity_on_hand) > 1000
ORDER BY total_quantity DESC
LIMIT 10
