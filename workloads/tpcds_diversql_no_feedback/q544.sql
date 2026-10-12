WITH ws_filtered AS (
    SELECT ws.*, 
           array[ws.ws_quantity, ws.ws_net_paid] AS qty_paid_arr
    FROM web_sales ws
    WHERE ws.ws_ship_mode_sk IN (
          SELECT sm.sm_ship_mode_sk
          FROM ship_mode sm
          WHERE sm.sm_contract LIKE 'G%'
    )
    AND ws.ws_net_paid > 1000
    AND ws.ws_quantity BETWEEN 1 AND 20
    AND ws.ws_ext_discount_amt < 5000
    AND ws.ws_sold_time_sk IS NOT NULL
    AND ws.ws_warehouse_sk IS NOT NULL
)
SELECT
    w.w_warehouse_name,
    sm.sm_code,
    td.t_shift,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_paid,
    metric_value,
    ws.ws_net_paid_inc_ship,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY ws.ws_net_paid DESC) AS warehouse_net_paid_rank,
    ROW_NUMBER() OVER (ORDER BY ws.ws_net_paid_inc_ship DESC) AS overall_row_num
FROM ws_filtered ws
RIGHT JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
CROSS JOIN UNNEST(ws.qty_paid_arr) AS t(metric_value)
WHERE sm.sm_code IN ('AIR', 'SEA')
  AND td.t_shift = 'first'
  AND w.w_state = 'CA'
  AND w.w_gmt_offset BETWEEN -8.0 AND -5.0
  AND sm.sm_type = 'EXPRESS'
  AND td.t_hour BETWEEN 8 AND 12
ORDER BY w.w_warehouse_name, ws.ws_net_paid DESC
LIMIT 100
