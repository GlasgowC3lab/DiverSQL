WITH ws_agg AS (
    SELECT
        i.i_item_sk,
        t.t_hour,
        SUM(ws.ws_net_profit) AS total_ws_net_profit,
        SUM(ws.ws_quantity) AS total_ws_quantity
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws.ws_ship_mode_sk = 3
      AND i.i_category = 'Electronics'
    GROUP BY i.i_item_sk, t.t_hour
),
sr_agg AS (
    SELECT
        i.i_item_sk,
        t.t_hour,
        SUM(sr.sr_net_loss) AS total_sr_net_loss,
        SUM(sr.sr_return_quantity) AS total_sr_return_qty
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND sr.sr_store_sk = 12
    GROUP BY i.i_item_sk, t.t_hour
),
cr_agg AS (
    SELECT
        i.i_item_sk,
        t.t_hour,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        SUM(cr.cr_return_quantity) AS total_cr_return_qty
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cr.cr_warehouse_sk = 7
    GROUP BY i.i_item_sk, t.t_hour
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ws.t_hour,
    ws.total_ws_net_profit,
    ws.total_ws_quantity,
    COALESCE(sr.total_sr_net_loss, 0) AS store_return_net_loss,
    COALESCE(cr.total_cr_net_loss, 0) AS catalog_return_net_loss,
    (ws.total_ws_net_profit - COALESCE(sr.total_sr_net_loss, 0) - COALESCE(cr.total_cr_net_loss, 0)) AS net_profit_after_returns,
    (ws.total_ws_quantity - COALESCE(sr.total_sr_return_qty, 0) - COALESCE(cr.total_cr_return_qty, 0)) AS net_quantity_sold
FROM ws_agg ws
JOIN item i
    ON ws.i_item_sk = i.i_item_sk
LEFT JOIN sr_agg sr
    ON sr.i_item_sk = ws.i_item_sk AND sr.t_hour = ws.t_hour
LEFT JOIN cr_agg cr
    ON cr.i_item_sk = ws.i_item_sk AND cr.t_hour = ws.t_hour
WHERE ws.total_ws_net_profit > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
