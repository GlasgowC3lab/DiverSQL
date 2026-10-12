WITH sales AS (
    SELECT
        cs.cs_order_number AS order_number,
        dd.d_date AS order_date,
        sm.sm_carrier AS ship_carrier,
        wh.w_warehouse_name AS warehouse_name,
        cs.cs_net_paid_inc_tax AS net_amount
    FROM tpcds.catalog_sales cs
    TABLESAMPLE BERNOULLI (5)
    JOIN tpcds.date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    WHERE dd.d_year = 2002
      AND sm.sm_carrier = 'UPS'
      AND wh.w_country = 'United States'
),
returns AS (
    SELECT
        cr.cr_order_number AS order_number,
        dd.d_date AS order_date,
        sm.sm_carrier AS ship_carrier,
        wh.w_warehouse_name AS warehouse_name,
        -cr.cr_net_loss AS net_amount
    FROM tpcds.catalog_returns cr
    TABLESAMPLE BERNOULLI (5)
    JOIN tpcds.catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    WHERE dd.d_year = 2002
      AND sm.sm_carrier = 'UPS'
      AND wh.w_country = 'United States'
),
combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
)
SELECT
    order_number,
    order_date,
    ship_carrier,
    warehouse_name,
    net_amount,
    ROW_NUMBER() OVER (ORDER BY net_amount DESC) AS row_num
FROM combined
ORDER BY net_amount DESC
LIMIT 100
