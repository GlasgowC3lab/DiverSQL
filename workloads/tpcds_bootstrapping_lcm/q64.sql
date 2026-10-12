WITH inv_agg AS (
    SELECT inv.inv_date_sk,
           SUM(inv.inv_quantity_on_hand) AS total_qty,
           COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM inventory inv
    GROUP BY inv.inv_date_sk
),
web_access_agg AS (
    SELECT wp.wp_access_date_sk,
           COUNT(*) AS access_page_count,
           AVG(wp.wp_char_count) AS avg_char_count
    FROM web_page wp
    GROUP BY wp.wp_access_date_sk
)
SELECT
    cp.cp_type,
    cp.cp_department,
    cp.cp_catalog_page_number,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    inv_agg.total_qty,
    inv_agg.distinct_items,
    store.s_store_name,
    store.s_state,
    web.wp_type,
    web.wp_char_count,
    web.wp_image_count,
    web_access_agg.access_page_count,
    web_access_agg.avg_char_count,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_type ORDER BY inv_agg.total_qty DESC) AS rank_qty
FROM catalog_page cp
JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
JOIN inv_agg ON inv_agg.inv_date_sk = d.d_date_sk
JOIN store ON store.s_closed_date_sk = d.d_date_sk
JOIN web_page web ON web.wp_creation_date_sk = d.d_date_sk
JOIN web_access_agg ON web_access_agg.wp_access_date_sk = d.d_date_sk
WHERE cp.cp_type IS NOT NULL
  AND store.s_state IS NOT NULL
ORDER BY rank_qty
LIMIT 100
