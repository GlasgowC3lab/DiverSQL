WITH cs_agg AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(cs.cs_net_profit) AS cs_total_profit
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_shift
),
ws_agg AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(ws.ws_net_profit) AS ws_total_profit
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_shift
),
wr_agg AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_shift
)
SELECT
    cs.t_hour,
    cs.t_shift,
    cs.cs_total_profit,
    ws.ws_total_profit,
    wr.total_return_loss,
    (cs.cs_total_profit + ws.ws_total_profit - wr.total_return_loss) AS net_profit_adj,
    CASE
        WHEN (cs.cs_total_profit + ws.ws_total_profit - wr.total_return_loss) >= 100000 THEN 'High'
        WHEN (cs.cs_total_profit + ws.ws_total_profit - wr.total_return_loss) >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY (cs.cs_total_profit + ws.ws_total_profit - wr.total_return_loss) DESC) AS profit_rank
FROM cs_agg cs
JOIN ws_agg ws
    ON cs.t_hour = ws.t_hour AND cs.t_shift = ws.t_shift
JOIN wr_agg wr
    ON cs.t_hour = wr.t_hour AND cs.t_shift = wr.t_shift
ORDER BY profit_rank
