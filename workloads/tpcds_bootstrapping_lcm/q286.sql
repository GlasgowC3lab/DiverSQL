SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    c.c_birth_year,
    (d_sales.d_year - c.c_birth_year) AS age_at_first_sales,
    (d_ship.d_year - c.c_birth_year) AS age_at_first_ship,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    d_ship.d_date AS ship_date,
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month_seq,
    d_sales.d_date AS sales_date,
    date_diff('day', d_ship.d_date, d_sales.d_date) AS days_between_ship_and_sales,
    d_wp_creation.d_year AS wp_creation_year,
    d_wp_creation.d_month_seq AS wp_creation_month_seq,
    d_wp_creation.d_date AS wp_creation_date,
    d_wp_access.d_year AS wp_access_year,
    d_wp_access.d_month_seq AS wp_access_month_seq,
    d_wp_access.d_date AS wp_access_date,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    wp.wp_char_count,
    wp.wp_max_ad_count,
    s.s_city,
    s.s_state,
    s.s_country,
    s.s_market_desc,
    s.s_floor_space,
    s.s_tax_percentage,
    SUM(wp.wp_image_count) OVER (PARTITION BY c.c_customer_id) AS total_images_per_customer,
    SUM(wp.wp_link_count) OVER (PARTITION BY c.c_customer_id) AS total_links_per_customer,
    AVG(wp.wp_char_count) OVER (PARTITION BY cd.cd_credit_rating) AS avg_char_count_by_credit_rating,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY wp.wp_image_count DESC) AS img_rank_by_gender
FROM customer c
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sales.d_date_sk
WHERE cd.cd_credit_rating = 'Excellent'
  AND s.s_state = 'CA'
  AND wp.wp_type = 'product'
ORDER BY days_between_ship_and_sales DESC
LIMIT 100
