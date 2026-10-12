SELECT
    c.c_customer_id,
    c.c_birth_country,
    CASE WHEN c.c_birth_year < 1970 THEN 'Pre-1970' ELSE '1970+' END AS birth_era,
    c.c_birth_month % 2 AS month_parity,
    d_cust_sales.d_year AS sales_year,
    d_ws_open.d_year AS site_open_year,
    s.s_division_name,
    s.s_state,
    ws.web_market_manager,
    wp.wp_type,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    AVG(ws.web_tax_percentage) AS avg_site_tax,
    COUNT(*) AS total_rows
FROM web_site ws
JOIN date_dim d_ws_open
    ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ws_open.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_cust_sales
    ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_cust_sales.d_year BETWEEN 2000 AND 2020
GROUP BY
    c.c_customer_id,
    c.c_birth_country,
    CASE WHEN c.c_birth_year < 1970 THEN 'Pre-1970' ELSE '1970+' END,
    c.c_birth_month % 2,
    d_cust_sales.d_year,
    d_ws_open.d_year,
    s.s_division_name,
    s.s_state,
    ws.web_market_manager,
    wp.wp_type
ORDER BY total_rows DESC
LIMIT 100
