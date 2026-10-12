WITH aggregated AS (
    SELECT
        d_inv.d_year,
        d_inv.d_month_seq,
        SUM(inventory.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT store.s_store_id) AS store_count,
        AVG(store.s_gmt_offset) AS avg_store_gmt_offset,
        SUM(web_page.wp_link_count) AS total_links,
        SUM(web_page.wp_image_count) AS total_images,
        COUNT(DISTINCT web_site.web_site_id) AS site_count,
        AVG(web_site.web_gmt_offset) AS avg_site_gmt_offset
    FROM
        inventory
        JOIN date_dim d_inv
            ON inventory.inv_date_sk = d_inv.d_date_sk
        JOIN store
            ON store.s_closed_date_sk = d_inv.d_date_sk
        JOIN web_page
            ON web_page.wp_creation_date_sk = d_inv.d_date_sk
        JOIN date_dim d_access
            ON web_page.wp_access_date_sk = d_access.d_date_sk
        JOIN web_site
            ON web_site.web_open_date_sk = d_inv.d_date_sk
        JOIN date_dim d_close
            ON web_site.web_close_date_sk = d_close.d_date_sk
    WHERE
        d_inv.d_year = 2023
        AND d_access.d_weekend = 'N'
        AND d_close.d_year = d_inv.d_year
    GROUP BY
        d_inv.d_year,
        d_inv.d_month_seq
)
SELECT
    d_year,
    d_month_seq,
    total_inventory,
    store_count,
    avg_store_gmt_offset,
    total_links,
    total_images,
    site_count,
    avg_site_gmt_offset,
    RANK() OVER (ORDER BY total_inventory DESC) AS inventory_qty_rank
FROM
    aggregated
ORDER BY
    total_inventory DESC
LIMIT 100
