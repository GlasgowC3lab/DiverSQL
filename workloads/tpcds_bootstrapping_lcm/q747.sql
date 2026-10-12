SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_store_closed.d_date AS store_closed_date,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sales.d_date AS first_sales_date,
    d_ship.d_date AS first_ship_date,
    DATE_DIFF('day', d_sales.d_date, d_ship.d_date) AS days_between_sales_and_ship,
    d_review.d_date AS last_review_date,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_count,
    SUM(COALESCE(wp.wp_char_count, 0)) AS total_characters,
    AVG(COALESCE(wp.wp_image_count, 0)) AS avg_image_count,
    MAX(d_wp_access.d_date) AS last_access_date,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY DATE_DIFF('day', d_sales.d_date, d_ship.d_date) DESC) AS sales_ship_rank
FROM date_dim d_store_closed
JOIN store s
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN customer c
    ON c.c_last_review_date = d_store_closed.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_store_closed.d_date,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sales.d_date,
    d_ship.d_date,
    d_review.d_date
ORDER BY
    days_between_sales_and_ship DESC,
    s.s_store_id
