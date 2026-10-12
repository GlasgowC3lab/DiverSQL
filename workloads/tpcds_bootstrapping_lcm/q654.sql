SELECT
    c.c_birth_year,
    CASE WHEN c.c_birth_month <= 6 THEN 'H1' ELSE 'H2' END AS birth_half,
    ca.ca_country,
    s.s_state,
    d_store.d_year AS store_closed_year,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    SUM(CASE WHEN d_sales.d_year = d_wp_creation.d_year THEN 1 ELSE 0 END) AS same_year_sales_creation,
    AVG(d_wp_access.d_month_seq) AS avg_access_month_seq,
    MIN(d_review.d_date) AS earliest_review_date,
    SUM(date_diff('day', d_ship.d_date, d_sales.d_date)) AS total_ship_sales_day_diff,
    COUNT(*) AS total_rows
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_store.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_store.d_year BETWEEN 2015 AND 2022
GROUP BY
    c.c_birth_year,
    CASE WHEN c.c_birth_month <= 6 THEN 'H1' ELSE 'H2' END,
    ca.ca_country,
    s.s_state,
    d_store.d_year
HAVING COUNT(DISTINCT wp.wp_web_page_id) > 5
ORDER BY total_rows DESC
LIMIT 100
