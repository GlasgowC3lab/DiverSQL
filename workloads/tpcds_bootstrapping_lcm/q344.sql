SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    cc.cc_state AS call_center_state,
    d_cc_closed.d_year AS call_center_closed_year,
    d_cc_open.d_year AS call_center_open_year,
    date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS call_center_open_days,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_store.d_year AS store_closed_year,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    c.c_birth_year,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    d_cust_sales.d_year AS first_sales_year,
    d_cust_sales.d_date AS first_sales_date,
    (d_cust_sales.d_year - c.c_birth_year) AS age_at_first_sale,
    (cc.cc_employees + s.s_number_employees) AS total_employees,
    (cc.cc_tax_percentage + s.s_tax_percentage) AS combined_tax_percentage
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cust_sales
    ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY call_center_open_days DESC, total_employees DESC
LIMIT 100
