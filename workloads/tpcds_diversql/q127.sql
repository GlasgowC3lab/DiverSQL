WITH inv_summary AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'Inventory' AS metric,
        SUM(i.inv_quantity_on_hand) AS metric_value,
        CASE WHEN SUM(i.inv_quantity_on_hand) > 1000 THEN 'High' ELSE 'Low' END AS classification
    FROM inventory i
    INNER JOIN item it ON i.inv_item_sk = it.i_item_sk
    INNER JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE it.i_brand = 'BrandX'
    GROUP BY w.w_warehouse_name
),
return_summary AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'Returns' AS metric,
        SUM(wr.wr_return_amt_inc_tax) AS metric_value,
        CASE WHEN SUM(wr.wr_return_amt_inc_tax) > 5000 THEN 'BigLoss' ELSE 'SmallLoss' END AS classification
    FROM web_returns wr
    INNER JOIN item it ON wr.wr_item_sk = it.i_item_sk
    INNER JOIN inventory i ON i.inv_item_sk = it.i_item_sk
    INNER JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE it.i_brand = 'BrandX'
    GROUP BY w.w_warehouse_name
)
SELECT *
FROM inv_summary
UNION ALL
SELECT *
FROM return_summary
ORDER BY warehouse_name, metric
LIMIT 100
