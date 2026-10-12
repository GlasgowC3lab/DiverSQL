SELECT
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    d_closed.d_date AS closure_date,
    d_open.d_date AS open_date,
    d_sales.d_date AS first_sales_date,
    d_review.d_date AS last_review_date,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(CASE WHEN d_sales.d_date <= d_review.d_date THEN 1 ELSE 0 END) AS customers_sales_before_review,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    date_diff('day', d_open.d_date, d_closed.d_date) AS cc_lifespan_days,
    date_diff('day', d_sales.d_date, d_review.d_date) AS sales_to_review_days
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    d_closed.d_date,
    d_open.d_date,
    d_sales.d_date,
    d_review.d_date
ORDER BY num_customers DESC
LIMIT 100
