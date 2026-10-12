WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_time_sk,
        SUM(ws.ws_net_profit) AS order_net_profit
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_meal_time = 'dinner'
      AND t.t_am_pm = 'PM'
    GROUP BY
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_time_sk
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_reason_sk,
        SUM(wr.wr_net_loss) AS order_return_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN time_dim tr
        ON wr.wr_returned_time_sk = tr.t_time_sk
    WHERE tr.t_meal_time = 'dinner'
      AND tr.t_am_pm = 'PM'
    GROUP BY
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_reason_sk
)
SELECT
    ws_site.web_name,
    ws_site.web_city,
    r.r_reason_desc,
    SUM(sales_agg.order_net_profit) AS total_sales_profit,
    COALESCE(SUM(returns_agg.order_return_loss), 0) AS total_return_loss,
    SUM(sales_agg.order_net_profit) - COALESCE(SUM(returns_agg.order_return_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT sales_agg.ws_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT returns_agg.wr_order_number) AS distinct_return_orders,
    RANK() OVER (PARTITION BY ws_site.web_name ORDER BY SUM(sales_agg.order_net_profit) - COALESCE(SUM(returns_agg.order_return_loss), 0) DESC) AS reason_rank
FROM sales_agg
LEFT JOIN returns_agg
    ON sales_agg.ws_order_number = returns_agg.wr_order_number
   AND sales_agg.ws_item_sk = returns_agg.wr_item_sk
JOIN web_site ws_site
    ON sales_agg.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN reason r
    ON returns_agg.wr_reason_sk = r.r_reason_sk
GROUP BY
    ws_site.web_name,
    ws_site.web_city,
    r.r_reason_desc
HAVING SUM(sales_agg.order_net_profit) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
