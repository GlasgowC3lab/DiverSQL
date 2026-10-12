SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cp.cp_department,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    COUNT(DISTINCT s.s_store_id) AS stores_closed_on_end_date,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_start_date,
    COUNT(DISTINCT inv.inv_item_sk) AS distinct_items_on_start_date,
    SUM(wp.wp_image_count) AS total_image_count_creation_and_access,
    AVG(wp.wp_link_count) AS avg_link_count
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_start.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
   AND wp.wp_access_date_sk = d_end.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cp.cp_department,
    d_start.d_date,
    d_end.d_date
ORDER BY cp.cp_catalog_page_id
