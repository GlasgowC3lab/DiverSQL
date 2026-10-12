SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_call_center_id,
    cc.cc_name,
    d_store.d_year AS store_close_year,
    d_cc_open.d_year AS cc_open_year,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_percentage,
    AVG(date_diff('day', d_store.d_date, d_promo_end.d_date)) AS avg_promo_duration_days,
    MAX(d_cust_last_review.d_date) AS latest_customer_review_date,
    CASE
        WHEN SUM(p.p_cost) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS promo_cost_category
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_store.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_store.d_date_sk
JOIN date_dim d_cust_first_sales
    ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN date_dim d_cust_last_review
    ON c.c_last_review_date = d_cust_last_review.d_date_sk
WHERE cc.cc_state = s.s_state
  AND d_cc_open.d_date <= d_store.d_date
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_call_center_id,
    cc.cc_name,
    d_store.d_year,
    d_cc_open.d_year
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY total_promo_cost DESC
LIMIT 20
