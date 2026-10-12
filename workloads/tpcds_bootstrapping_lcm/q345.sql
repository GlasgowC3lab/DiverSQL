SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_page_number,
    start_dd.d_date AS catalog_start_date,
    end_dd.d_date AS catalog_end_date,
    s.s_store_id,
    s.s_city,
    s.s_state,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_end_date,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages_created_on_end_date,
    MIN(wp.wp_url) AS sample_url,
    MAX(creation_dd.d_date) AS latest_creation_date,
    MIN(access_dd.d_date) AS earliest_access_date
FROM catalog_page cp
JOIN date_dim start_dd
  ON cp.cp_start_date_sk = start_dd.d_date_sk
JOIN date_dim end_dd
  ON cp.cp_end_date_sk = end_dd.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = end_dd.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = end_dd.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = end_dd.d_date_sk
JOIN date_dim creation_dd
  ON wp.wp_creation_date_sk = creation_dd.d_date_sk
JOIN date_dim access_dd
  ON wp.wp_access_date_sk = access_dd.d_date_sk
WHERE cp.cp_department = 'Electronics'
  AND s.s_state = 'NY'
  AND i.inv_quantity_on_hand > 0
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_page_number,
    start_dd.d_date,
    end_dd.d_date,
    s.s_store_id,
    s.s_city,
    s.s_state
ORDER BY total_inventory_on_end_date DESC
LIMIT 100
