SELECT 
    cp.cp_department,
    s.s_state,
    d_start.d_year,
    d_start.d_quarter_name,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created,
    AVG(s.s_floor_space) AS avg_floor_space,
    MIN(d_end.d_date) AS catalog_end_date,
    MAX(d_wp_access.d_date) AS latest_web_access,
    SUM(CASE WHEN d_store.d_date BETWEEN d_start.d_date AND d_end.d_date THEN 1 ELSE 0 END) AS stores_closed_in_period
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
JOIN inventory i ON TRUE
JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
JOIN store s ON TRUE
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_page wp ON TRUE
JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE 
    d_inv.d_date BETWEEN d_start.d_date AND d_end.d_date
    AND d_store.d_date BETWEEN d_start.d_date AND d_end.d_date
    AND d_wp_access.d_date BETWEEN d_start.d_date AND d_end.d_date
    AND cp.cp_type = 'CATALOG'
GROUP BY 
    cp.cp_department,
    s.s_state,
    d_start.d_year,
    d_start.d_quarter_name
HAVING 
    SUM(i.inv_quantity_on_hand) > 0
ORDER BY 
    total_inventory DESC
LIMIT 50
