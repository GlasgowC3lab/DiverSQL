SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d_closed.d_date AS closed_date,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_open.d_day_name AS cc_open_day_name,
    d_open.d_weekend AS cc_open_weekend,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    MIN(p.p_discount_active) AS any_discount_active,
    COUNT(DISTINCT p.p_promo_id) AS num_promotions,
    MAX(d_end.d_date) AS latest_promo_end_date,
    SUM(CASE WHEN p.p_channel_tv IS NOT NULL THEN 1 ELSE 0 END) AS tv_channel_promos,
    SUM(CASE WHEN p.p_channel_email IS NOT NULL THEN 1 ELSE 0 END) AS email_channel_promos
FROM store s
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_closed.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE s.s_state = 'TX'
  AND cc.cc_state = 'TX'
  AND d_closed.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d_closed.d_date,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_open.d_day_name,
    d_open.d_weekend
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 100
