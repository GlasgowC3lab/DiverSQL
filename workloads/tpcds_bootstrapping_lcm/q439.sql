WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty,
           COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    GROUP BY inv_date_sk
),
store_agg AS (
    SELECT s_closed_date_sk,
           COUNT(DISTINCT s_store_id) AS stores_closed,
           SUM(s_floor_space) AS total_floor_space,
           AVG(s_gmt_offset) AS avg_gmt_offset
    FROM store
    GROUP BY s_closed_date_sk
),
web_site_open_agg AS (
    SELECT web_open_date_sk,
           COUNT(DISTINCT web_site_id) AS sites_opened,
           SUM(web_tax_percentage) AS total_tax_opened
    FROM web_site
    GROUP BY web_open_date_sk
),
web_site_close_agg AS (
    SELECT web_close_date_sk,
           COUNT(DISTINCT web_site_id) AS sites_closed,
           SUM(web_tax_percentage) AS total_tax_closed
    FROM web_site
    GROUP BY web_close_date_sk
),
web_page_cre_agg AS (
    SELECT wp_creation_date_sk,
           COUNT(DISTINCT wp_web_page_sk) AS pages_created,
           AVG(wp_char_count) AS avg_char_count_created,
           SUM(wp_image_count) AS total_image_created
    FROM web_page
    GROUP BY wp_creation_date_sk
),
web_page_acc_agg AS (
    SELECT wp_access_date_sk,
           COUNT(DISTINCT wp_web_page_sk) AS pages_accessed,
           AVG(wp_char_count) AS avg_char_count_accessed,
           SUM(wp_image_count) AS total_image_accessed
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    COALESCE(inv.total_qty, 0)                     AS total_inventory_qty,
    COALESCE(inv.distinct_items, 0)               AS distinct_inventory_items,
    COALESCE(stores.stores_closed, 0)             AS stores_closed_on_date,
    COALESCE(stores.total_floor_space, 0)         AS total_floor_space_of_closed_stores,
    COALESCE(ws_open.sites_opened, 0)             AS sites_opened_on_date,
    COALESCE(ws_open.total_tax_opened, 0)         AS total_tax_of_sites_opened,
    COALESCE(ws_close.sites_closed, 0)            AS sites_closed_on_date,
    COALESCE(ws_close.total_tax_closed, 0)        AS total_tax_of_sites_closed,
    COALESCE(wp_cre.pages_created, 0)             AS pages_created_on_date,
    COALESCE(wp_cre.avg_char_count_created, 0)    AS avg_char_count_created,
    COALESCE(wp_cre.total_image_created, 0)       AS total_image_created,
    COALESCE(wp_acc.pages_accessed, 0)            AS pages_accessed_on_date,
    COALESCE(wp_acc.avg_char_count_accessed, 0)   AS avg_char_count_accessed,
    COALESCE(wp_acc.total_image_accessed, 0)      AS total_image_accessed
FROM date_dim d
LEFT JOIN inv_agg           inv   ON inv.inv_date_sk      = d.d_date_sk
LEFT JOIN store_agg         stores ON stores.s_closed_date_sk = d.d_date_sk
LEFT JOIN web_site_open_agg ws_open ON ws_open.web_open_date_sk = d.d_date_sk
LEFT JOIN web_site_close_agg ws_close ON ws_close.web_close_date_sk = d.d_date_sk
LEFT JOIN web_page_cre_agg  wp_cre ON wp_cre.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_page_acc_agg  wp_acc ON wp_acc.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
ORDER BY d.d_date
