SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    date_diff('day', d_start.d_date, d_end.d_date) AS catalog_duration_days,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    wp.wp_url,
    wp.wp_type AS web_page_type,
    wp.wp_image_count,
    wp.wp_link_count,
    d_wp_creation.d_date AS page_creation_date,
    d_wp_creation.d_year AS page_creation_year,
    d_end.d_date AS page_access_date,
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    d_cust_ship.d_date AS first_ship_date,
    d_cust_sales.d_date AS first_sales_date,
    date_diff('day', d_cust_ship.d_date, current_date) AS days_since_first_ship,
    date_diff('day', d_cust_sales.d_date, current_date) AS days_since_first_sales,
    CASE
        WHEN d_start.d_month_seq = d_end.d_month_seq THEN 'SameMonth'
        ELSE 'DiffMonth'
    END AS catalog_month_relation,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d_start.d_date DESC) AS store_page_rank
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp
    ON wp.wp_access_date_sk = d_end.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN customer cust
    ON wp.wp_customer_sk = cust.c_customer_sk
JOIN date_dim d_cust_ship
    ON cust.c_first_shipto_date_sk = d_cust_ship.d_date_sk
JOIN date_dim d_cust_sales
    ON cust.c_first_sales_date_sk = d_cust_sales.d_date_sk
WHERE cp.cp_type = 'PROMO'
  AND s.s_state = 'CA'
ORDER BY cp.cp_catalog_page_number DESC, store_page_rank
LIMIT 100
