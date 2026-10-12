WITH
  catalog_agg AS (
    SELECT
      cs.cs_order_number AS order_number,
      ca.ca_state AS state,
      cc.cc_name AS descriptor,
      SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_net_profit > 0
    GROUP BY cs.cs_order_number, ca.ca_state, cc.cc_name
  ),
  web_agg AS (
    SELECT
      ws.ws_order_number AS order_number,
      ca.ca_state AS state,
      sm.sm_type AS descriptor,
      SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_net_profit > 0
    GROUP BY ws.ws_order_number, ca.ca_state, sm.sm_type
  ),
  combined AS (
    SELECT 'catalog' AS source, order_number, state, descriptor, net_profit
    FROM catalog_agg
    UNION ALL
    SELECT 'web' AS source, order_number, state, descriptor, net_profit
    FROM web_agg
  ),
  high_profit_states AS (
    SELECT state
    FROM combined
    GROUP BY state
    HAVING SUM(net_profit) > 100000
  )
SELECT
  source,
  order_number,
  state,
  descriptor,
  net_profit,
  SUM(net_profit) OVER (
    PARTITION BY state
    ORDER BY net_profit DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_profit
FROM combined
WHERE state NOT IN (SELECT state FROM high_profit_states)
ORDER BY net_profit DESC
LIMIT 100
