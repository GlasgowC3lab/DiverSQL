WITH aggregated AS (
    SELECT w.w_city,
           w.w_state,
           w.w_warehouse_name,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_quantity) AS total_quantity_sold,
           AVG(ws.ws_ext_sales_price) AS avg_sales_price,
           SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 200
      AND p.p_discount_active = 'Y'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY w.w_city, w.w_state, w.w_warehouse_name
)
SELECT a.w_city,
       a.w_state,
       a.w_warehouse_name,
       a.total_net_profit,
       a.total_quantity_sold,
       a.avg_sales_price,
       a.total_inventory_on_hand,
       a.total_net_profit / NULLIF(a.total_quantity_sold, 0) AS profit_per_unit,
       RANK() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY profit_rank
LIMIT 10
