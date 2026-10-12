SELECT
    cc.cc_name AS call_center_name,
    cc.cc_manager AS call_center_manager,
    d_cc_open.d_year AS cc_open_year,
    d_cc_close.d_year AS cc_close_year,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store_close.d_year AS store_close_year,
    p.p_promo_name,
    p.p_discount_active,
    d_promo_start.d_year AS promo_start_year,
    d_promo_end.d_year AS promo_end_year,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT CASE WHEN p.p_channel_tv IS NOT NULL THEN c.c_customer_id END) AS customers_via_tv,
    COUNT(DISTINCT CASE WHEN p.p_channel_email IS NOT NULL THEN c.c_customer_id END) AS customers_via_email
FROM call_center cc
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_close
    ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_close.d_date_sk
JOIN date_dim d_store_close
    ON s.s_closed_date_sk = d_store_close.d_date_sk
JOIN promotion p
    ON true
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer c
    ON true
JOIN date_dim d_cust_sales
    ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
JOIN date_dim d_cust_ship
    ON c.c_first_shipto_date_sk = d_cust_ship.d_date_sk
JOIN date_dim d_cust_review
    ON c.c_last_review_date = d_cust_review.d_date_sk
WHERE
    d_promo_start.d_date >= d_cc_open.d_date
    AND d_promo_end.d_date <= d_store_close.d_date
    AND d_cust_sales.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
    AND d_cust_ship.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
GROUP BY
    cc.cc_name,
    cc.cc_manager,
    d_cc_open.d_year,
    d_cc_close.d_year,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store_close.d_year,
    p.p_promo_name,
    p.p_discount_active,
    d_promo_start.d_year,
    d_promo_end.d_year
ORDER BY total_promo_cost DESC
LIMIT 20
