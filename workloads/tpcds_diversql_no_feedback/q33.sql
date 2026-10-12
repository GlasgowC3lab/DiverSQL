WITH store_agg AS (
    SELECT
        td.t_hour AS hour,
        CAST(hd.hd_vehicle_count AS VARCHAR) AS category,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS metric
    FROM store_returns sr
    RIGHT OUTER JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    FULL OUTER JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY td.t_hour, hd.hd_vehicle_count
),
web_agg AS (
    SELECT
        td.t_hour AS hour,
        sm.sm_type AS category,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS metric
    FROM web_sales ws
    RIGHT OUTER JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    FULL OUTER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY td.t_hour, sm.sm_type
)
SELECT hour, category, metric
FROM store_agg
UNION
SELECT hour, category, metric
FROM web_agg
ORDER BY hour DESC, metric DESC
LIMIT 100
