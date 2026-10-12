WITH inv_snapshot AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_date_sk = 2451046
    GROUP BY inv_warehouse_sk
),
sales_agg AS (
    SELECT
        ws.ws_warehouse_sk AS warehouse_sk,
        sm.sm_type AS ship_mode_type,
        wp.wp_type AS page_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_profit_per_sale,
        COUNT(*) AS transaction_cnt
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451053
    GROUP BY ws.ws_warehouse_sk, sm.sm_type, wp.wp_type
)
SELECT
    w.w_warehouse_name,
    s.ship_mode_type,
    s.page_type,
    s.total_net_profit,
    s.total_quantity,
    s.avg_profit_per_sale,
    s.transaction_cnt,
    COALESCE(i.total_on_hand, 0) AS inventory_on_hand,
    ROUND(s.total_net_profit / NULLIF(s.total_quantity, 0), 2) AS profit_per_unit
FROM sales_agg s
JOIN warehouse w
    ON s.warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_snapshot i
    ON w.w_warehouse_sk = i.inv_warehouse_sk
WHERE s.total_net_profit > 10000
ORDER BY s.total_net_profit DESC
LIMIT 50
