SELECT 
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    d_cc_open.d_date AS cc_open_date,
    d_date.d_date AS cc_close_date,
    date_diff('day', d_cc_open.d_date, d_date.d_date) AS cc_days_open,
    s.s_store_name,
    s.s_city AS store_city,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    ca.ca_city AS cust_addr_city,
    ca.ca_state AS cust_addr_state,
    d_sales.d_date AS first_sales_date,
    d_review.d_date AS last_review_date,
    date_diff('day', d_sales.d_date, d_review.d_date) AS days_between_sales_and_review,
    RANK() OVER (PARTITION BY cc.cc_call_center_id ORDER BY date_diff('day', d_sales.d_date, d_review.d_date) DESC) AS sales_review_rank,
    ROW_NUMBER() OVER (ORDER BY cc.cc_call_center_id) AS rn
FROM call_center cc
JOIN date_dim d_date
    ON cc.cc_closed_date_sk = d_date.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_date.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_date.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY cc.cc_call_center_id
LIMIT 100
