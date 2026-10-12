WITH warehouse_inventory AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
sales_agg AS (
    SELECT
        w.w_state,
        p.p_channel_tv,
        wi.total_inventory_on_hand,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount
    FROM web_sales ws
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN warehouse_inventory wi
      ON w.w_warehouse_sk = wi.inv_warehouse_sk
    WHERE hd.hd_income_band_sk IN (5,6)
      AND hd.hd_vehicle_count >= 2
      AND p.p_discount_active = 'Y'
      AND p.p_channel_tv IS NOT NULL
      AND ws.ws_net_profit > 0
    GROUP BY w.w_state, p.p_channel_tv, wi.total_inventory_on_hand
    HAVING SUM(ws.ws_net_profit) > 10000
)
SELECT
    s.w_state,
    s.p_channel_tv,
    s.total_inventory_on_hand,
    s.total_net_profit,
    s.total_quantity_sold,
    s.avg_discount_amount,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
ORDER BY profit_rank
LIMIT 10
