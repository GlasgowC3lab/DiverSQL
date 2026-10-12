SELECT
    cp.cp_department,
    i.i_brand,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    SUM(i.i_current_price) AS total_price,
    AVG(i.i_current_price) AS avg_price,
    COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_modes,
    COUNT(DISTINCT ca.ca_state) AS distinct_states
FROM
    catalog_page cp
    JOIN item i ON cp.cp_catalog_number = i.i_category_id
    LEFT JOIN ship_mode sm ON cp.cp_type = sm.sm_type
    JOIN customer_address ca ON ca.ca_address_sk = i.i_item_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cp.cp_catalog_page_sk
WHERE
    cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
    AND i.i_current_price > 10
    AND ca.ca_country = 'United States'
GROUP BY
    cp.cp_department,
    i.i_brand
HAVING
    COUNT(*) >= 5
ORDER BY
    total_price DESC
LIMIT 100
