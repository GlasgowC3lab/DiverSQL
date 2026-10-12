WITH ws_agg AS (
  SELECT
    ws.ws_warehouse_sk,
    COUNT(*) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_net_profit) AS total_net_profit
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
    AND ws.ws_ship_mode_sk IN (1, 2, 3)
  GROUP BY ws.ws_warehouse_sk
)
SELECT
  w.w_warehouse_name,
  w.w_city,
  w.w_state,
  a.order_cnt,
  a.total_net_paid,
  a.avg_discount,
  a.total_net_profit,
  RANK() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank
FROM ws_agg a
JOIN warehouse w ON a.ws_warehouse_sk = w.w_warehouse_sk
WHERE a.total_net_profit > 10000
ORDER BY profit_rank
LIMIT 10
