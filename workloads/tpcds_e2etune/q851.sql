WITH ws_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 100
    GROUP BY ws.ws_warehouse_sk, ws.ws_item_sk, ws.ws_sold_date_sk
),
sr_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    WHERE sr.sr_return_amt > 100
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk
)
SELECT
    w.w_warehouse_name,
    ws_agg.ws_sold_date_sk AS sales_date_sk,
    ws_agg.ws_item_sk AS item_sk,
    ws_agg.total_net_profit,
    COALESCE(sr_agg.total_return_loss, 0) AS total_return_loss,
    ws_agg.total_net_profit - COALESCE(sr_agg.total_return_loss, 0) AS net_contribution,
    RANK() OVER (PARTITION BY ws_agg.ws_sold_date_sk ORDER BY (ws_agg.total_net_profit - COALESCE(sr_agg.total_return_loss, 0)) DESC) AS rank_per_day
FROM ws_agg
LEFT JOIN sr_agg
    ON ws_agg.ws_item_sk = sr_agg.sr_item_sk
    AND ws_agg.ws_sold_date_sk = sr_agg.sr_returned_date_sk
JOIN warehouse w
    ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
WHERE (ws_agg.total_net_profit - COALESCE(sr_agg.total_return_loss, 0)) > 0
ORDER BY ws_agg.ws_sold_date_sk, net_contribution DESC
LIMIT 200
