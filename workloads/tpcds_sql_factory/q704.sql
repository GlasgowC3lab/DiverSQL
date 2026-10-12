WITH ws_agg AS (
    SELECT
        ws.ws_order_number,
        t.t_hour,
        t.t_shift,
        SUM(ws.ws_net_profit) AS ws_total_profit,
        SUM(ws.ws_net_paid_inc_tax) AS ws_total_paid
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY ws.ws_order_number, t.t_hour, t.t_shift
),
wr_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_order_number
),
cs_hour_agg AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(cs.cs_net_profit) AS cs_total_profit
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_shift
),
order_profit AS (
    SELECT
        ws.ws_order_number,
        ws.t_hour,
        ws.t_shift,
        ws.ws_total_profit,
        COALESCE(wr.total_return_loss, 0) AS total_return_loss,
        cs.cs_total_profit,
        (ws.ws_total_profit - COALESCE(wr.total_return_loss, 0) + cs.cs_total_profit) AS net_profit_adj,
        CASE
            WHEN (ws.ws_total_profit - COALESCE(wr.total_return_loss, 0) + cs.cs_total_profit) >= 200000 THEN 'Very High'
            WHEN (ws.ws_total_profit - COALESCE(wr.total_return_loss, 0) + cs.cs_total_profit) >= 100000 THEN 'High'
            WHEN (ws.ws_total_profit - COALESCE(wr.total_return_loss, 0) + cs.cs_total_profit) >= 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        DENSE_RANK() OVER (ORDER BY (ws.ws_total_profit - COALESCE(wr.total_return_loss, 0) + cs.cs_total_profit) DESC) AS profit_rank
    FROM ws_agg ws
    LEFT JOIN wr_agg wr
        ON ws.ws_order_number = wr.wr_order_number
    JOIN cs_hour_agg cs
        ON ws.t_hour = cs.t_hour AND ws.t_shift = cs.t_shift
)
SELECT
    ws_order_number,
    t_hour,
    t_shift,
    ws_total_profit,
    total_return_loss,
    cs_total_profit,
    net_profit_adj,
    profit_category,
    profit_rank
FROM order_profit
WHERE profit_rank <= 10
ORDER BY profit_rank
