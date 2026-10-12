WITH sales_data AS (
    SELECT
        cs.cs_order_number AS order_number,
        'sale' AS transaction_type,
        cs.cs_net_paid AS amount,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        sm.sm_ship_mode_id AS ship_mode_id,
        d.d_year AS year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2020
),
returns_data AS (
    SELECT
        cr.cr_order_number AS order_number,
        'return' AS transaction_type,
        cr.cr_return_amount AS amount,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        sm.sm_ship_mode_id AS ship_mode_id,
        d.d_year AS year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2020
),
combined AS (
    SELECT order_number, transaction_type, amount, ship_mode_id, warehouse_sk, year
    FROM sales_data
    UNION ALL
    SELECT order_number, transaction_type, amount, ship_mode_id, warehouse_sk, year
    FROM returns_data
)
SELECT
    c.order_number,
    c.transaction_type,
    c.amount,
    c.ship_mode_id,
    COALESCE(w.w_warehouse_name, 'No Warehouse') AS warehouse_name,
    c.year
FROM combined c
FULL OUTER JOIN warehouse w
    ON c.warehouse_sk = w.w_warehouse_sk
ORDER BY c.amount DESC
LIMIT 100
