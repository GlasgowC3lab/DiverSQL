WITH returns_agg AS (
    SELECT
        w.w_city,
        'return_amount' AS metric,
        sum(cr.cr_return_amount) AS total_value,
        concat(w.w_city, '-', 'return_amount') AS label
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        regexp_like(cp.cp_catalog_page_id, '^AAAA.*A$')
        AND cp.cp_type LIKE '%monthly%'
    GROUP BY w.w_city
),
inventory_agg AS (
    SELECT
        w.w_city,
        'inventory_qty' AS metric,
        sum(inv.inv_quantity_on_hand) AS total_value,
        concat(w.w_city, '-', 'inventory_qty') AS label
    FROM inventory inv
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_street_name LIKE '%Ridge%'
        AND regexp_extract(w.w_zip, '(\\d{3})', 1) = '292'
    GROUP BY w.w_city
)
SELECT w_city, metric, total_value, label
FROM (
    SELECT w_city, metric, total_value, label FROM returns_agg
    UNION
    SELECT w_city, metric, total_value, label FROM inventory_agg
) AS combined
ORDER BY w_city, metric
LIMIT 100
