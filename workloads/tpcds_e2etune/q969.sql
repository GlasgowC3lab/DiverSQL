WITH store_agg AS (
   SELECT
      ca.ca_state AS state,
      i.i_category AS category,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(ss.ss_quantity) AS store_qty
   FROM store_sales ss
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE t.t_shift = 'Evening'
     AND i.i_category = 'Sports'
   GROUP BY ca.ca_state, i.i_category
),
web_agg AS (
   SELECT
      ca.ca_state AS state,
      i.i_category AS category,
      SUM(ws.ws_net_profit) AS web_profit,
      SUM(ws.ws_quantity) AS web_qty
   FROM web_sales ws
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE t.t_shift = 'Evening'
     AND i.i_category = 'Sports'
     AND sm.sm_type = 'AIR'
   GROUP BY ca.ca_state, i.i_category
)
SELECT
   COALESCE(s.state, w.state) AS state,
   COALESCE(s.category, w.category) AS category,
   COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) AS total_profit,
   COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty,
   RANK() OVER (ORDER BY COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) DESC) AS profit_rank
FROM store_agg s
FULL OUTER JOIN web_agg w
   ON s.state = w.state AND s.category = w.category
WHERE COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) > 10000
ORDER BY total_profit DESC
LIMIT 50
