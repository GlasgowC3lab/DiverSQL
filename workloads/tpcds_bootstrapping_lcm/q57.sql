SELECT
    s.s_store_id,
    s.s_city,
    cc.cc_call_center_id,
    cc.cc_city,
    d_store.d_year,
    d_store.d_month_seq,
    COUNT(DISTINCT wp.wp_web_page_id) AS total_web_pages,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links,
    AVG(wp.wp_char_count) AS avg_char_count,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_count,
    SUM(CASE WHEN c.c_birth_year < 1960 THEN 1 ELSE 0 END) AS customers_born_before_1960,
    DATE_DIFF('day', MIN(d_cc_open.d_date), MIN(d_store.d_date)) AS cc_open_to_close_days,
    CASE
        WHEN SUM(wp.wp_link_count) = 0 THEN NULL
        ELSE SUM(wp.wp_image_count) * 1.0 / SUM(wp.wp_link_count)
    END AS image_to_link_ratio,
    DATE_DIFF('day', MIN(d_store.d_date), MIN(d_wp_access.d_date)) AS days_between_creation_and_access
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_store.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_c_shipto
    ON c.c_first_shipto_date_sk = d_c_shipto.d_date_sk
WHERE s.s_state = 'CA'
  AND d_c_shipto.d_year = d_store.d_year
GROUP BY
    s.s_store_id,
    s.s_city,
    cc.cc_call_center_id,
    cc.cc_city,
    d_store.d_year,
    d_store.d_month_seq
HAVING COUNT(DISTINCT wp.wp_web_page_id) > 5
ORDER BY total_images DESC
LIMIT 100
