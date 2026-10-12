WITH sub1 AS (
    SELECT
        i.inv_warehouse_sk,
        w.w_warehouse_name,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        CASE WHEN SUM(i.inv_quantity_on_hand) > 500 THEN 'HIGH' ELSE 'LOW' END AS qty_category
    FROM (
        SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
    ) i
    FULL OUTER JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        i.inv_warehouse_sk,
        w.w_warehouse_name
    HAVING
        SUM(i.inv_quantity_on_hand) IS NOT NULL
),
sub2 AS (
    SELECT
        ws.ws_warehouse_sk AS inv_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_qty,
        CASE WHEN SUM(ws.ws_quantity) > 500 THEN 'HIGH' ELSE 'LOW' END AS qty_category
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_net_paid_inc_ship > 2000
    GROUP BY
        ws.ws_warehouse_sk,
        w.w_warehouse_name
    HAVING
        SUM(ws.ws_quantity) > 0
),
combined AS (
    SELECT inv_warehouse_sk, w_warehouse_name, total_qty, qty_category FROM sub1
    UNION ALL
    SELECT inv_warehouse_sk, w_warehouse_name, total_qty, qty_category FROM sub2
)
SELECT
    c.inv_warehouse_sk,
    c.w_warehouse_name,
    c.total_qty,
    c.qty_category
FROM combined c
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws3
    WHERE ws3.ws_warehouse_sk = c.inv_warehouse_sk
      AND ws3.ws_net_paid_inc_ship > 1500
)
ORDER BY c.total_qty DESC, c.inv_warehouse_sk
