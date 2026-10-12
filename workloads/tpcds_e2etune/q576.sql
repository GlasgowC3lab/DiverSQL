WITH sales_agg AS (
    SELECT
        ws.ws_promo_sk,
        t_sales.t_hour,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t_sales ON ws.ws_sold_time_sk = t_sales.t_time_sk
    WHERE p.p_channel_email = 'N'
      AND p.p_promo_sk IN (1, 2, 3)
      AND t_sales.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_promo_sk, t_sales.t_hour
),
returns_agg AS (
    SELECT
        ws.ws_promo_sk,
        t_return.t_hour AS return_hour,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS total_return_orders
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
    WHERE ws.ws_promo_sk IN (1, 2, 3)
      AND t_return.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_promo_sk, t_return.t_hour
)
SELECT
    p.p_promo_id,
    s.t_hour AS sale_hour,
    s.total_net_profit,
    s.total_discount,
    s.total_orders,
    s.total_quantity,
    s.avg_net_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.total_return_orders, 0) AS total_return_orders,
    CASE WHEN s.total_orders = 0 THEN 0
         ELSE (COALESCE(r.total_return_orders, 0) * 100.0 / s.total_orders)
    END AS return_rate_pct,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ws_promo_sk = r.ws_promo_sk
   AND s.t_hour = r.return_hour
JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
WHERE s.total_net_profit > 0
ORDER BY s.total_net_profit DESC
LIMIT 100
