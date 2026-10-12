WITH catalog_agg AS (
  SELECT
    ca.ca_state AS state,
    sm.sm_ship_mode_id AS ship_mode,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450840
    AND t.t_hour BETWEEN 9 AND 17
    AND cs.cs_ext_discount_amt > 100.0
  GROUP BY ca.ca_state, sm.sm_ship_mode_id
),
web_agg AS (
  SELECT
    ca.ca_state AS state,
    sm.sm_ship_mode_id AS ship_mode,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450840
    AND t.t_hour BETWEEN 9 AND 17
    AND ws.ws_ext_discount_amt > 100.0
  GROUP BY ca.ca_state, sm.sm_ship_mode_id
)
SELECT
  state,
  ship_mode,
  SUM(total_net_profit) AS total_net_profit,
  AVG(avg_discount) AS avg_discount,
  SUM(sales_cnt) AS total_sales_cnt
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
) combined
GROUP BY state, ship_mode
ORDER BY total_net_profit DESC
LIMIT 10
