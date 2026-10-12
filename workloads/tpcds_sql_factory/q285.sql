WITH sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        w.w_city,
        ws.ws_sold_date_sk AS date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_transactions
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_state, w.w_city, ws.ws_sold_date_sk
),
returns_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        w.w_city,
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_state, w.w_city, cr.cr_returned_date_sk
)
SELECT
    s.w_warehouse_sk,
    s.w_state,
    s.w_city,
    s.date_sk,
    s.total_sales_amount,
    s.total_sales_profit,
    r.total_return_amount,
    r.total_return_loss,
    CASE
        WHEN s.total_sales_profit = 0 THEN NULL
        ELSE ROUND(r.total_return_loss / s.total_sales_profit, 4)
    END AS loss_to_profit_ratio,
    CASE
        WHEN s.total_sales_profit = 0 THEN 'No Sales'
        WHEN r.total_return_loss / s.total_sales_profit < 0.5 THEN 'Healthy'
        ELSE 'Alert'
    END AS profit_health_flag,
    SUM(s.total_sales_amount) OVER (PARTITION BY s.w_warehouse_sk ORDER BY s.date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_amount,
    LAG(s.total_sales_profit) OVER (PARTITION BY s.w_warehouse_sk ORDER BY s.date_sk) AS previous_day_profit,
    RANK() OVER (PARTITION BY s.w_warehouse_sk ORDER BY s.total_sales_profit DESC) AS sales_profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.w_warehouse_sk = r.w_warehouse_sk
    AND s.date_sk = r.date_sk
WHERE s.total_sales_amount > 0
ORDER BY s.w_warehouse_sk, s.date_sk
