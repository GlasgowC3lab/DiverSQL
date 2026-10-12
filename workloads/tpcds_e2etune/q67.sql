WITH store_agg AS (
  SELECT t.t_hour AS hour_of_day,
         SUM(ss.ss_net_profit) AS store_net_profit,
         SUM(ss.ss_quantity) AS store_quantity
  FROM store_sales ss
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  WHERE i.i_category_id = 3
    AND t.t_hour BETWEEN 8 AND 20
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY t.t_hour
),
web_agg AS (
  SELECT t.t_hour AS hour_of_day,
         SUM(ws.ws_net_profit) AS web_net_profit,
         SUM(ws.ws_quantity) AS web_quantity
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE i.i_category_id = 3
    AND t.t_hour BETWEEN 8 AND 20
    AND c.c_preferred_cust_flag = 'Y'
    AND wsite.web_country = 'USA'
  GROUP BY t.t_hour
),
combined AS (
  SELECT COALESCE(s.hour_of_day, w.hour_of_day) AS hour_of_day,
         COALESCE(s.store_net_profit, 0) AS store_net_profit,
         COALESCE(w.web_net_profit, 0) AS web_net_profit,
         COALESCE(s.store_quantity, 0) AS store_quantity,
         COALESCE(w.web_quantity, 0) AS web_quantity,
         COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
         COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
  FROM store_agg s
  FULL OUTER JOIN web_agg w ON s.hour_of_day = w.hour_of_day
)
SELECT hour_of_day,
       store_net_profit,
       web_net_profit,
       total_net_profit,
       store_quantity,
       web_quantity,
       total_quantity,
       RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
       PERCENT_RANK() OVER (ORDER BY total_quantity) AS quantity_percentile
FROM combined
ORDER BY hour_of_day
