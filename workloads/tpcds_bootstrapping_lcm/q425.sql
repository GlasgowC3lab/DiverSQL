SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_ship.d_date AS first_ship_date,
    d_sales.d_date AS first_sales_date,
    d_wp_access.d_date AS web_page_access_date,
    d_wp_creation.d_date AS web_page_creation_date,
    wp.wp_url,
    wp.wp_type,
    p.p_promo_name,
    p.p_cost,
    p.p_discount_active,
    d_promo_end.d_date AS promotion_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_country,
    SUM(p.p_cost) OVER (PARTITION BY c.c_customer_id) AS total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_wp_access.d_date DESC) AS recent_page_rank
FROM customer c
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
WHERE p.p_discount_active = 'Y'
ORDER BY total_promo_cost DESC, c.c_customer_id
LIMIT 100
