SELECT
    d_closed.d_year AS year,
    p.p_promo_name,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_count,
    COUNT(DISTINCT s.s_store_sk) AS store_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cc.cc_employees) AS avg_cc_employees,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    SUM(cc.cc_employees * 1.0) / NULLIF(SUM(s.s_floor_space), 0) AS employees_per_sqft,
    MAX(p.p_response_target) AS max_response_target,
    MIN(d_closed.d_date) AS earliest_closed_date,
    MAX(d_closed.d_date) AS latest_closed_date
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_closed.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE cc.cc_country = 'United States'
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY d_closed.d_year, p.p_promo_name
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 50
