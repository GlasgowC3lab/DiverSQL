WITH ss_agg AS (
    SELECT s.s_city AS city,
           i.i_class AS item_class,
           SUM(ss.ss_quantity) AS total_sales_qty,
           SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_units = 'Cup'
    GROUP BY s.s_city, i.i_class
),
sr_agg AS (
    SELECT s.s_city AS city,
           i.i_class AS item_class,
           SUM(sr.sr_return_quantity) AS total_return_qty,
           SUM(sr.sr_net_loss) AS total_return_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_units = 'Cup'
    GROUP BY s.s_city, i.i_class
),
ws_agg AS (
    SELECT i.i_class AS item_class,
           SUM(ws.ws_quantity) AS total_web_qty,
           SUM(ws.ws_net_profit) AS total_web_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_units = 'Cup'
    GROUP BY i.i_class
)
SELECT
    ss.city,
    ss.item_class,
    ss.total_sales_qty,
    ss.total_sales_net_profit,
    COALESCE(sr.total_return_qty, 0) AS total_return_qty,
    COALESCE(sr.total_return_net_loss, 0) AS total_return_net_loss,
    ss.total_sales_net_profit - COALESCE(sr.total_return_net_loss, 0) AS net_profit_after_returns,
    COALESCE(ws.total_web_qty, 0) AS total_web_qty,
    COALESCE(ws.total_web_net_profit, 0) AS total_web_net_profit,
    CASE WHEN ss.total_sales_net_profit > 0
         THEN COALESCE(ws.total_web_net_profit, 0) / ss.total_sales_net_profit
         ELSE NULL END AS web_to_store_profit_ratio,
    RANK() OVER (PARTITION BY ss.city ORDER BY (ss.total_sales_net_profit - COALESCE(sr.total_return_net_loss, 0)) DESC) AS city_profit_rank
FROM ss_agg ss
LEFT JOIN sr_agg sr
  ON ss.city = sr.city AND ss.item_class = sr.item_class
LEFT JOIN ws_agg ws
  ON ss.item_class = ws.item_class
ORDER BY net_profit_after_returns DESC
LIMIT 100
