SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_name AS call_center_name,
    cc.cc_manager,
    cp.cp_type,
    cp.cp_description,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    MIN(d_store_closed.d_date) AS store_closed_date,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MIN(d_cp_end.d_date) AS catalog_page_end_date,
    MIN(d_cust_ship.d_date) AS customer_first_ship_date,
    MIN(d_cust_review.d_date) AS customer_last_review_date
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_cust_ship
    ON c.c_first_shipto_date_sk = d_cust_ship.d_date_sk
JOIN date_dim d_cust_review
    ON c.c_last_review_date = d_cust_review.d_date_sk
WHERE s.s_country = 'United States'
  AND cc.cc_tax_percentage > 0
  AND cp.cp_type IS NOT NULL
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_name,
    cc.cc_manager,
    cp.cp_type,
    cp.cp_description
ORDER BY distinct_customers DESC
LIMIT 100
