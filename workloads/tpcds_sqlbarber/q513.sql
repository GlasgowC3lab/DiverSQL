SELECT i.inv_date_sk,
       i.inv_item_sk,
       w.w_warehouse_id,
       CASE WHEN i.inv_quantity_on_hand > 541 THEN 'High' ELSE 'Low' END AS quantity_status,
       i.inv_quantity_on_hand * 1.1 AS adjusted_quantity,
       CASE WHEN w.w_gmt_offset < -7.00 THEN 'West' ELSE 'East' END AS region_indicator,
       CONCAT(w.w_city, ', ', w.w_state) AS location
FROM inventory i
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_date_sk = 2451067
