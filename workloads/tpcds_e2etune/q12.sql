WITH agg AS (
    SELECT
        w.ws_warehouse_sk,
        t.t_hour,
        t.t_shift,
        SUM(w.ws_net_profit) AS total_net_profit,
        SUM(w.ws_quantity) AS total_units_sold,
        AVG(i.inv_quantity_on_hand) AS avg_inv_qty
    FROM web_sales w
    JOIN time_dim t
        ON w.ws_sold_time_sk = t.t_time_sk
    JOIN inventory i
        ON i.inv_item_sk = w.ws_item_sk
        AND i.inv_warehouse_sk = w.ws_warehouse_sk
        AND i.inv_date_sk = w.ws_sold_date_sk
    WHERE t.t_hour BETWEEN 0 AND 4
      AND i.inv_quantity_on_hand > 200
      AND w.ws_net_profit > 0
    GROUP BY w.ws_warehouse_sk, t.t_hour, t.t_shift
)
SELECT
    ws_warehouse_sk,
    t_hour,
    t_shift,
    total_net_profit,
    total_units_sold,
    avg_inv_qty,
    total_net_profit / NULLIF(total_units_sold, 0) AS profit_per_unit,
    RANK() OVER (PARTITION BY ws_warehouse_sk ORDER BY total_net_profit DESC) AS profit_hour_rank,
    SUM(total_net_profit) OVER (PARTITION BY ws_warehouse_sk ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit
FROM agg
ORDER BY ws_warehouse_sk, profit_hour_rank
