WITH sales_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        w.w_city AS warehouse_city,
        i.i_category AS item_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_level
    FROM web_sales ws
    RIGHT OUTER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = ws.ws_item_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
    )
    GROUP BY w.w_warehouse_id, w.w_city, i.i_category
),
returns_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        w.w_city AS warehouse_city,
        i.i_category AS item_category,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amt_inc_tax) AS total_sales,
        CASE WHEN SUM(cr.cr_net_loss) > 5000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_level
    FROM catalog_returns cr
    RIGHT OUTER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = cr.cr_item_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
    )
    GROUP BY w.w_warehouse_id, w.w_city, i.i_category
)
SELECT
    combined.warehouse_id,
    combined.warehouse_city,
    combined.item_category,
    combined.total_quantity,
    combined.total_sales,
    combined.profit_level
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) AS combined
ORDER BY combined.warehouse_id, combined.item_category
LIMIT 100
