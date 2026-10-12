/* goal: Compare the total financial impact of catalog returns (net loss) versus catalog sales (net paid including tax) for each warehouse and ship mode over a recent period, and list the combined results ordered for paging. */
WITH returns_cte AS (
    SELECT
        w.w_warehouse_id          AS warehouse_id,
        w.w_warehouse_name        AS warehouse_name,
        sm.sm_ship_mode_id        AS ship_mode_id,
        CAST('Return' AS varchar) AS metric_type,
        SUM(cr.cr_net_loss)       AS total_amount
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450948 AND 2451053
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        sm.sm_ship_mode_id
),
sales_cte AS (
    SELECT
        w.w_warehouse_id          AS warehouse_id,
        w.w_warehouse_name        AS warehouse_name,
        sm.sm_ship_mode_id        AS ship_mode_id,
        CAST('Sale' AS varchar)   AS metric_type,
        SUM(cs.cs_net_paid_inc_tax) AS total_amount
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450948 AND 2451053
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        sm.sm_ship_mode_id
)
SELECT
    warehouse_id,
    warehouse_name,
    ship_mode_id,
    metric_type,
    total_amount
FROM returns_cte
UNION ALL
SELECT
    warehouse_id,
    warehouse_name,
    ship_mode_id,
    metric_type,
    total_amount
FROM sales_cte
ORDER BY warehouse_id, ship_mode_id, metric_type
OFFSET 0 LIMIT 100
