WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        td.t_hour,
        td.t_am_pm,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        ws.ws_sales_price,
        ws.ws_ext_ship_cost,
        sm.sm_carrier,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_state,
        ARRAY[sm.sm_type, sm.sm_carrier] AS carrier_info
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN time_dim td_ret
        ON sr.sr_return_time_sk = td_ret.t_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
)
SELECT
    sm_carrier,
    w_warehouse_name,
    t_hour,
    t_am_pm,
    carrier_attribute,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(COALESCE(sr_return_quantity, 0)) AS total_return_qty,
    SUM(COALESCE(sr_net_loss, 0)) AS total_return_loss,
    SUM(ws_sales_price) AS total_web_sales,
    SUM(ws_ext_ship_cost) AS total_ship_cost,
    ROW_NUMBER() OVER (PARTITION BY sm_carrier ORDER BY SUM(ss_ext_sales_price) DESC) AS rank_by_carrier_sales
FROM base
CROSS JOIN UNNEST(carrier_info) AS u (carrier_attribute)
WHERE ss_quantity > 1
  AND ss_ext_sales_price BETWEEN 100 AND 5000
  AND ss_net_profit > 0
  AND t_hour BETWEEN 8 AND 20
  AND sm_carrier IS NOT NULL
  AND w_state = 'CA'
GROUP BY ROLLUP (sm_carrier, w_warehouse_name, t_hour, t_am_pm, carrier_attribute)
ORDER BY total_sales DESC
LIMIT 100
