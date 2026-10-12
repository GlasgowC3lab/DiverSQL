WITH sales_agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
),
returns_agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
)
SELECT
    s.ship_mode_type,
    s.total_sales,
    s.total_profit,
    r.total_return_amount,
    r.total_loss,
    CASE
        WHEN r.total_loss = 0 THEN NULL
        ELSE s.total_profit / r.total_loss
    END AS profit_loss_ratio,
    CASE
        WHEN s.total_profit > r.total_loss THEN 'Profit'
        ELSE 'Loss'
    END AS overall_status,
    DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY s.ship_mode_type ORDER BY r.total_loss DESC) AS loss_rank_within_mode
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ship_mode_type = r.ship_mode_type
ORDER BY sales_rank
