WITH warehouse_sales AS (
    SELECT
        w.w_warehouse_name,
        sm.sm_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450900 AND 2451050
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND inv.inv_quantity_on_hand > 200
    GROUP BY w.w_warehouse_name, sm.sm_type
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    ws.w_warehouse_name,
    ws.sm_type,
    ws.total_net_profit,
    ws.total_quantity_sold,
    ws.avg_inventory_on_hand,
    RANK() OVER (ORDER BY ws.total_net_profit DESC) AS profit_rank
FROM warehouse_sales ws
ORDER BY ws.total_net_profit DESC
LIMIT 50
