WITH sales_by_ship_mode AS (
    SELECT
        ws.ws_ship_mode_sk AS ship_mode_sk,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_quantity) AS total_sales_qty,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ws.ws_ship_mode_sk
),
catalog_return_by_ship_mode AS (
    SELECT
        cr.cr_ship_mode_sk AS ship_mode_sk,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
        COUNT(*) AS cnt_catalog_returns
    FROM catalog_returns cr
    WHERE cr.cr_call_center_sk IN (1, 13, 22)
    GROUP BY cr.cr_ship_mode_sk
),
web_return_by_ship_mode AS (
    SELECT
        ws.ws_ship_mode_sk AS ship_mode_sk,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        COUNT(*) AS cnt_web_returns
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ws.ws_ship_mode_sk
)
SELECT
    sm.sm_carrier,
    sm.sm_type,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(c.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    COALESCE(w.total_web_return_loss, 0) AS total_web_return_loss,
    (COALESCE(s.total_sales_profit, 0) - COALESCE(c.total_catalog_return_loss, 0) - COALESCE(w.total_web_return_loss, 0)) AS net_profit_after_returns,
    CASE
        WHEN COALESCE(s.total_sales_qty, 0) > 0 THEN
            CAST((COALESCE(c.total_catalog_return_qty, 0) + COALESCE(w.total_web_return_qty, 0)) AS double) / COALESCE(s.total_sales_qty, 1)
        ELSE 0
    END AS return_rate
FROM ship_mode sm
LEFT JOIN sales_by_ship_mode s
    ON sm.sm_ship_mode_sk = s.ship_mode_sk
LEFT JOIN catalog_return_by_ship_mode c
    ON sm.sm_ship_mode_sk = c.ship_mode_sk
LEFT JOIN web_return_by_ship_mode w
    ON sm.sm_ship_mode_sk = w.ship_mode_sk
WHERE (COALESCE(s.total_sales_profit, 0) - COALESCE(c.total_catalog_return_loss, 0) - COALESCE(w.total_web_return_loss, 0)) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 10
