WITH wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_order_number,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_order_number
),
ws_events AS (
    SELECT
        t.t_time,
        ws.ws_net_profit - COALESCE(wr_agg.total_return_loss, 0) AS profit_adj
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN wr_agg
        ON ws.ws_item_sk = wr_agg.wr_item_sk
           AND ws.ws_order_number = wr_agg.wr_order_number
),
cs_events AS (
    SELECT
        t.t_time,
        cs.cs_net_profit AS profit_adj
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
),
combined AS (
    SELECT t_time, profit_adj FROM cs_events
    UNION ALL
    SELECT t_time, profit_adj FROM ws_events
)
SELECT
    t_time,
    profit_adj,
    SUM(profit_adj) OVER (ORDER BY t_time ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    AVG(profit_adj) OVER (ORDER BY t_time ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS moving_avg_5,
    CASE WHEN profit_adj > 0 THEN 'Gain' ELSE 'Loss' END AS profit_sign
FROM combined
ORDER BY t_time
