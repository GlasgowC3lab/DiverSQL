WITH high_cost AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        'HighCost' AS sales_category
    FROM web_sales ws
    RIGHT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ext_wholesale_cost > 3000 OR ws.ws_ext_wholesale_cost IS NULL
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
),
low_cost AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        'LowCost' AS sales_category
    FROM web_sales ws
    RIGHT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ext_wholesale_cost <= 3000 OR ws.ws_ext_wholesale_cost IS NULL
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
),
combined AS (
    SELECT * FROM high_cost
    UNION ALL
    SELECT * FROM low_cost
)
SELECT
    sm_ship_mode_id,
    sm_carrier,
    total_sales,
    sales_category,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM combined
ORDER BY total_sales DESC, sales_category
LIMIT 100
