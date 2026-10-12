SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    cc.cc_call_center_id,
    cc.cc_division_name,
    d_cc_open.d_year AS cc_open_year,
    d_cc_closed.d_year AS cc_closed_year,
    d_store_closed.d_year AS store_closed_year,
    d_cust_sales.d_year AS first_sales_year,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    MAX(d_cust_ship.d_date) AS latest_ship_date,
    MIN(d_cust_review.d_date) AS earliest_review_date,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY s.s_floor_space DESC) AS rn_state_by_floor
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_store_closed.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_cust_ship
    ON c.c_first_shipto_date_sk = d_cust_ship.d_date_sk
JOIN date_dim d_cust_sales
    ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
JOIN date_dim d_cust_review
    ON c.c_last_review_date = d_cust_review.d_date_sk
WHERE s.s_floor_space > 0
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    cc.cc_call_center_id,
    cc.cc_division_name,
    d_cc_open.d_year,
    d_cc_closed.d_year,
    d_store_closed.d_year,
    d_cust_sales.d_year
HAVING COUNT(DISTINCT c.c_customer_id) >= 5
ORDER BY num_customers DESC, s.s_floor_space DESC
LIMIT 100
