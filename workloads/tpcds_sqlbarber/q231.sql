SELECT ws.ws_item_sk,
       ws.ws_quantity,
       ws.ws_wholesale_cost,
       ws.ws_ext_sales_price,
       ws.ws_quantity * ws.ws_wholesale_cost AS wholesale_total,
       CASE WHEN ws.ws_quantity > 79 THEN 'High Qty' ELSE 'Low Qty' END AS qty_category,
       w.w_state,
       w.w_gmt_offset,
       w.w_gmt_offset * ws.ws_ext_sales_price AS offset_price,
       CASE WHEN w.w_state = 'SC' THEN 'Target State' ELSE 'Other State' END AS state_flag
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_quantity > 100
  AND w.w_country = 'United States'
