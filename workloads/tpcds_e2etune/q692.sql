WITH ws_agg AS (
    SELECT t.t_hour AS hour_of_day,
           SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY t.t_hour
),
sr_agg AS (
    SELECT t.t_hour AS hour_of_day,
           SUM(sr.sr_net_loss) AS total_store_loss
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state IN ('TN', 'GA')
    GROUP BY t.t_hour
)
SELECT COALESCE(ws_agg.hour_of_day, sr_agg.hour_of_day) AS hour_of_day,
       ws_agg.total_web_profit,
       sr_agg.total_store_loss,
       (COALESCE(ws_agg.total_web_profit, 0) - COALESCE(sr_agg.total_store_loss, 0)) AS net_margin,
       RANK() OVER (ORDER BY (COALESCE(ws_agg.total_web_profit, 0) - COALESCE(sr_agg.total_store_loss, 0)) DESC) AS net_margin_rank
FROM ws_agg
FULL OUTER JOIN sr_agg
  ON ws_agg.hour_of_day = sr_agg.hour_of_day
WHERE (COALESCE(ws_agg.total_web_profit, 0) - COALESCE(sr_agg.total_store_loss, 0)) > 0
ORDER BY net_margin DESC
