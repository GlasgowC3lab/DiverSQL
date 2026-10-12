SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    d_shipto.d_date AS first_shipto_date,
    d_sales.d_date AS first_sales_date,
    d_sales.d_year AS first_sales_year,
    d_review.d_date AS last_review_date,
    d_review.d_week_seq AS review_week_seq,
    wp.wp_url,
    wp.wp_type,
    d_wp_create.d_date AS page_creation_date,
    d_wp_access.d_date AS page_access_date,
    date_diff('day', d_wp_create.d_date, d_wp_access.d_date) AS days_between_creation_and_access,
    date_diff('day', d_shipto.d_date, d_sales.d_date) AS days_between_shipto_and_sales,
    date_diff('day', d_wp_create.d_date, d_review.d_date) AS days_between_page_creation_and_review,
    inv.inv_quantity_on_hand,
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_closed_date_sk
FROM customer c
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_shipto
    ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_shipto.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_review.d_date_sk
JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE inv.inv_quantity_on_hand > 0
ORDER BY days_between_creation_and_access DESC, c.c_customer_id
LIMIT 100
