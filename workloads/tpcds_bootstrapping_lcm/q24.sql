SELECT
    cp.cp_department,
    cp.cp_type,
    d_cp_start.d_year AS start_year,
    d_cp_end.d_year AS end_year,
    c.c_birth_country,
    c.c_birth_month,
    s.s_state,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    COUNT(*) AS total_records,
    AVG(s.s_floor_space) AS avg_floor_space,
    SUM(CASE WHEN s.s_state = 'CA' THEN 1 ELSE 0 END) AS ca_store_count,
    MIN(d_c_ship.d_date) AS earliest_ship_date,
    MAX(d_c_sales.d_date) AS latest_sales_date
FROM catalog_page cp
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_c_ship
    ON c.c_first_shipto_date_sk = d_c_ship.d_date_sk
JOIN date_dim d_c_sales
    ON c.c_first_sales_date_sk = d_c_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_c_ship.d_date_sk
WHERE cp.cp_type = 'Featured'
  AND s.s_state IN ('CA', 'TX', 'NY')
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    cp.cp_department,
    cp.cp_type,
    d_cp_start.d_year,
    d_cp_end.d_year,
    c.c_birth_country,
    c.c_birth_month,
    s.s_state
HAVING COUNT(*) > 5
ORDER BY total_records DESC
LIMIT 100
