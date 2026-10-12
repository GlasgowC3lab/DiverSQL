WITH sales_adj AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        COALESCE(wr.wr_net_loss, 0) AS net_loss,
        (ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0)) AS adj_net_profit
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
),
profit_by_wh AS (
    SELECT
        wsit.web_name,
        wh.w_warehouse_name,
        SUM(sa.adj_net_profit) AS total_adj_profit,
        CASE
            WHEN SUM(sa.adj_net_profit) > 100000 THEN 'High'
            WHEN SUM(sa.adj_net_profit) BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM sales_adj sa
    JOIN warehouse wh ON sa.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site wsit ON sa.ws_web_site_sk = wsit.web_site_sk
    GROUP BY wsit.web_name, wh.w_warehouse_name
)
SELECT
    web_name,
    w_warehouse_name,
    total_adj_profit,
    profit_category,
    RANK() OVER (PARTITION BY web_name ORDER BY total_adj_profit DESC) AS warehouse_rank
FROM profit_by_wh
ORDER BY web_name, warehouse_rank
