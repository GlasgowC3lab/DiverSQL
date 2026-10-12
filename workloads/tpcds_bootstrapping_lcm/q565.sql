SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_market_manager,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_cp_end.d_year AS cp_end_year,
    p.p_promo_name,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_pages_count,
    AVG(p.p_cost) AS avg_promo_cost
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE
    s.s_state = 'CA'
    AND d_cc_closed.d_year = 2022
    AND p.p_discount_active = 'Y'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_market_manager,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_cp_end.d_year,
    p.p_promo_name
ORDER BY total_promo_cost DESC
LIMIT 100
