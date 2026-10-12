WITH latest_inv AS (
    SELECT inv_warehouse_sk, MAX(inv_date_sk) AS max_date
    FROM inventory
    GROUP BY inv_warehouse_sk
),
inv_latest AS (
    SELECT i.inv_warehouse_sk, i.inv_item_sk, i.inv_quantity_on_hand
    FROM inventory i
    JOIN latest_inv li ON i.inv_warehouse_sk = li.inv_warehouse_sk AND i.inv_date_sk = li.max_date
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    COALESCE(SUM(i.inv_quantity_on_hand), 0) AS latest_inventory_qty
FROM web_sales ws
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN inv_latest i
    ON w.w_warehouse_sk = i.inv_warehouse_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451053
GROUP BY w.w_warehouse_name, w.w_city, w.w_state
HAVING SUM(ws.ws_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 50
