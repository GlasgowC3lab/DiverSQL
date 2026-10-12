WITH ws_agg AS (
    SELECT td.t_hour,
           SUM(ws.ws_net_paid_inc_ship_tax) AS total_web_sales,
           SUM(ws.ws_net_profit) AS total_web_profit,
           COUNT(*) AS cnt_sales
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour
),
sr_agg AS (
    SELECT td.t_hour,
           SUM(sr.sr_net_loss) AS total_store_return_loss,
           COUNT(*) AS cnt_store_returns
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour
),
wr_agg AS (
    SELECT td.t_hour,
           SUM(wr.wr_net_loss) AS total_web_return_loss,
           COUNT(*) AS cnt_web_returns
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour
)
SELECT
    COALESCE(ws.t_hour, sr.t_hour, wr.t_hour) AS hour,
    COALESCE(ws.total_web_sales, 0) AS total_web_sales,
    COALESCE(ws.total_web_profit, 0) AS total_web_profit,
    COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
    (COALESCE(ws.total_web_profit, 0) - COALESCE(sr.total_store_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0)) AS net_hourly_impact,
    CASE 
        WHEN COALESCE(ws.total_web_sales, 0) = 0 THEN 0
        ELSE (COALESCE(wr.total_web_return_loss, 0) / COALESCE(ws.total_web_sales, 0)) * 100
    END AS web_return_loss_pct,
    RANK() OVER (ORDER BY (COALESCE(ws.total_web_profit, 0) - COALESCE(sr.total_store_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0)) DESC) AS profit_rank
FROM ws_agg ws
FULL OUTER JOIN sr_agg sr ON ws.t_hour = sr.t_hour
FULL OUTER JOIN wr_agg wr ON COALESCE(ws.t_hour, sr.t_hour) = wr.t_hour
ORDER BY net_hourly_impact DESC
LIMIT 24
