SELECT w.w_warehouse_name,
       w.w_state,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(ws.ws_net_profit) AS total_net_profit
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN (
    SELECT inv_warehouse_sk,
           inv_item_sk,
           inv_quantity_on_hand
    FROM inventory i
    WHERE i.inv_date_sk = 2450955
) inv_sub ON inv_sub.inv_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_sold_date_sk = 2451576
GROUP BY w.w_warehouse_name, w.w_state
HAVING SUM(cr.cr_return_amount) > 29.79
