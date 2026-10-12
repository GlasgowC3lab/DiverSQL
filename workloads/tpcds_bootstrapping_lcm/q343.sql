SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_preferred_cust_flag,
    wp.wp_url,
    wp.wp_char_count,
    wp.wp_image_count,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_name,
    ws.web_city,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
FROM date_dim d
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
   AND ws.web_close_date_sk = d.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d.d_date_sk
   AND c.c_first_sales_date_sk = d.d_date_sk
   AND c.c_last_review_date = d.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
   AND wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_access_date_sk = d.d_date_sk
ORDER BY c.c_customer_id
LIMIT 100
