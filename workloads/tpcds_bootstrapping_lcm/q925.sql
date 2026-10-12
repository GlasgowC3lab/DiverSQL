SELECT
    cc.cc_manager,
    s.s_manager,
    d_cc_closed.d_year AS closed_year,
    d_cc_closed.d_moy AS closed_month,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    SUM(wp.wp_image_count) AS total_images,
    AVG(wp.wp_image_count) AS avg_images_per_page,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(DATE_DIFF('day', d_cc_closed.d_date, d_wp_access.d_date)) AS avg_days_from_closed_to_access,
    SUM(CASE WHEN d_cust_sales.d_year = d_cc_open.d_year THEN 1 ELSE 0 END) AS customers_same_year_as_cc_open,
    MIN(d_cust_shipto.d_date) AS earliest_shipto_date,
    MAX(d_cust_review.d_date) AS latest_review_date
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
JOIN date_dim d_cust_review
    ON c.c_last_review_date = d_cust_review.d_date_sk
WHERE cc.cc_country = 'United States'
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_manager,
    s.s_manager,
    d_cc_closed.d_year,
    d_cc_closed.d_moy
ORDER BY
    closed_year DESC,
    closed_month DESC,
    distinct_pages DESC
LIMIT 100
