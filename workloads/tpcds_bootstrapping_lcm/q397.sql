WITH inv_by_date AS (
    SELECT
        i.inv_date_sk,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    GROUP BY i.inv_date_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d_cc_closed.d_date AS cc_closed_date,
    d_cc_open.d_date AS cc_open_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_store_closed.d_date AS store_closed_date,
    inv.total_qty,
    inv.distinct_items,
    CASE
        WHEN d_cc_closed.d_year = d_store_closed.d_year THEN 'Same Year'
        ELSE 'Different Year'
    END AS cc_store_year_cmp,
    CASE
        WHEN d_cc_closed.d_year = d_cc_open.d_year THEN 'Closed Same Year as Open'
        ELSE 'Closed Different Year'
    END AS cc_open_year_cmp,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY inv.total_qty DESC) AS store_rank
FROM call_center cc
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN inv_by_date inv ON inv.inv_date_sk = d_cc_closed.d_date_sk
WHERE cc.cc_tax_percentage > 0
  AND s.s_tax_percentage > 0
  AND inv.total_qty > 0
ORDER BY inv.total_qty DESC
LIMIT 100
