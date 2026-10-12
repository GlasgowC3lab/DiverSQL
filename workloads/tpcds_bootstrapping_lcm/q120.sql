WITH inv_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    GROUP BY inv_date_sk
),
store_closed_agg AS (
    SELECT
        s_closed_date_sk,
        COUNT(DISTINCT s_store_sk) AS stores_closed
    FROM store
    GROUP BY s_closed_date_sk
),
call_center_open_agg AS (
    SELECT
        cc_open_date_sk,
        COUNT(DISTINCT cc_call_center_sk) AS opened_call_centers
    FROM call_center
    GROUP BY cc_open_date_sk
),
call_center_closed_agg AS (
    SELECT
        cc_closed_date_sk,
        COUNT(DISTINCT cc_call_center_sk) AS closed_call_centers
    FROM call_center
    GROUP BY cc_closed_date_sk
),
web_page_creation_agg AS (
    SELECT
        wp_creation_date_sk,
        COUNT(DISTINCT wp_web_page_sk) AS pages_created
    FROM web_page
    GROUP BY wp_creation_date_sk
),
web_page_access_agg AS (
    SELECT
        wp_access_date_sk,
        COUNT(DISTINCT wp_web_page_sk) AS pages_accessed
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    d.d_date,
    COALESCE(i.total_qty, 0) AS total_inventory_quantity,
    COALESCE(i.distinct_items, 0) AS distinct_inventory_items,
    COALESCE(s.stores_closed, 0) AS stores_closed,
    COALESCE(cc_open.opened_call_centers, 0) AS call_centers_opened,
    COALESCE(cc_closed.closed_call_centers, 0) AS call_centers_closed,
    COALESCE(wc.pages_created, 0) AS pages_created,
    COALESCE(wa.pages_accessed, 0) AS pages_accessed,
    CASE WHEN COALESCE(s.stores_closed, 0) > 0
         THEN COALESCE(i.total_qty, 0) * 1.0 / s.stores_closed
         ELSE NULL
    END AS qty_per_closed_store,
    CASE WHEN COALESCE(cc_closed.closed_call_centers, 0) > 0
         THEN COALESCE(i.total_qty, 0) * 1.0 / cc_closed.closed_call_centers
         ELSE NULL
    END AS qty_per_closed_call_center
FROM
    date_dim d
    LEFT JOIN inv_agg i ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN store_closed_agg s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN call_center_open_agg cc_open ON cc_open.cc_open_date_sk = d.d_date_sk
    LEFT JOIN call_center_closed_agg cc_closed ON cc_closed.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN web_page_creation_agg wc ON wc.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_page_access_agg wa ON wa.wp_access_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2020 AND 2023
ORDER BY
    d.d_date DESC
LIMIT 200
