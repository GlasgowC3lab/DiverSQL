SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    cc.cc_state AS call_center_state,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_closed.d_date AS closed_date,
    d_open.d_date AS open_date,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(hd.hd_vehicle_count) AS total_vehicles,
    AVG(hd.hd_dep_count) AS avg_dependents,
    MIN(c.c_birth_year) AS youngest_birth_year,
    MAX(c.c_birth_year) AS oldest_birth_year
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_open.d_date_sk
JOIN date_dim d_c_ship
    ON c.c_first_shipto_date_sk = d_c_ship.d_date_sk
JOIN date_dim d_c_last_review
    ON c.c_last_review_date = d_c_last_review.d_date_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE d_c_ship.d_date >= d_open.d_date
  AND d_c_last_review.d_year = d_closed.d_year
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_closed.d_date,
    d_open.d_date
ORDER BY num_customers DESC
LIMIT 100
