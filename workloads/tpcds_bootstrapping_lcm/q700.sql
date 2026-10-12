SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_country,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_store_closed.d_year AS store_closed_year,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    COUNT(*) AS num_returns,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date,
    wp.wp_url,
    wp.wp_image_count,
    wp.wp_link_count,
    d_wp_creation.d_year AS page_creation_year,
    d_wp_access.d_year AS page_access_year,
    d_cust_first_sales.d_year AS first_sales_year,
    d_cust_first_ship.d_year AS first_ship_year,
    d_cust_last_review.d_year AS last_review_year,
    s.s_floor_space
FROM customer c
JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_cust_first_sales ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN date_dim d_cust_first_ship ON c.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN date_dim d_cust_last_review ON c.c_last_review_date = d_cust_last_review.d_date_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_country,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_store_closed.d_year,
    wp.wp_url,
    wp.wp_image_count,
    wp.wp_link_count,
    d_wp_creation.d_year,
    d_wp_access.d_year,
    d_cust_first_sales.d_year,
    d_cust_first_ship.d_year,
    d_cust_last_review.d_year,
    s.s_floor_space
ORDER BY total_return_amount DESC
LIMIT 100
