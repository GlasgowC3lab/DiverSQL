WITH sales_shipping AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        w.w_city,
        ws.ws_ship_mode_sk AS ship_mode_sk,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_ext_ship_cost) AS avg_sales_ship_cost,
        SUM(ws.ws_ext_ship_cost) AS total_sales_ship_cost
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_state, w.w_city, ws.ws_ship_mode_sk
),
returns_shipping AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        w.w_city,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        COUNT(*) AS returns_cnt,
        AVG(cr.cr_return_ship_cost) AS avg_return_ship_cost,
        SUM(cr.cr_fee) AS total_return_fee,
        SUM(cr.cr_return_ship_cost) AS total_return_ship_cost
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_state, w.w_city, cr.cr_ship_mode_sk
)
SELECT
    s.w_warehouse_sk,
    s.w_state,
    s.w_city,
    s.ship_mode_sk,
    s.sales_cnt,
    s.avg_sales_ship_cost,
    r.returns_cnt,
    r.avg_return_ship_cost,
    r.total_return_fee,
    CASE
        WHEN s.avg_sales_ship_cost > 20 THEN 'Expensive Sales Shipping'
        WHEN s.avg_sales_ship_cost > 10 THEN 'Moderate Sales Shipping'
        ELSE 'Low Sales Shipping'
    END AS sales_ship_cost_category,
    CASE
        WHEN r.avg_return_ship_cost > 15 THEN 'Expensive Return Shipping'
        WHEN r.avg_return_ship_cost > 8 THEN 'Moderate Return Shipping'
        ELSE 'Low Return Shipping'
    END AS return_ship_cost_category,
    (s.avg_sales_ship_cost - COALESCE(r.avg_return_ship_cost, 0)) AS ship_cost_diff,
    RANK() OVER (PARTITION BY s.w_warehouse_sk ORDER BY (s.avg_sales_ship_cost - COALESCE(r.avg_return_ship_cost, 0)) DESC) AS ship_cost_diff_rank,
    SUM(s.total_sales_ship_cost) OVER (PARTITION BY s.w_warehouse_sk) AS warehouse_total_sales_ship_cost,
    SUM(COALESCE(r.total_return_ship_cost, 0)) OVER (PARTITION BY s.w_warehouse_sk) AS warehouse_total_return_ship_cost
FROM sales_shipping s
LEFT JOIN returns_shipping r
    ON s.w_warehouse_sk = r.w_warehouse_sk
    AND s.ship_mode_sk = r.ship_mode_sk
WHERE s.sales_cnt > 0
ORDER BY s.w_warehouse_sk, ship_cost_diff_rank
