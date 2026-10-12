SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_gmt_offset,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    s.s_store_name,
    s.s_floor_space,
    s.s_city,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_char_count,
    d_wp_access.d_year AS wp_access_year,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_preferred_cust_flag,
    d_cust_shipto.d_year AS cust_shipto_year,
    d_cust_sales.d_year AS cust_sales_year
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_cust_shipto
    ON c.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
JOIN date_dim d_cust_sales
    ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
ORDER BY cc.cc_call_center_id, c.c_customer_id
LIMIT 100
