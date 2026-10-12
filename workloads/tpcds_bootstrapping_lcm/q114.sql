WITH promo_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_closed.d_date AS store_closed_date,
        d_open.d_date AS call_center_open_date,
        d_closed.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_cost) FILTER (WHERE p.p_discount_active = 'Y') AS avg_discounted_promo_cost,
        MAX(p.p_response_target) AS max_response_target,
        ROUND(AVG(cc.cc_tax_percentage), 2) AS avg_cc_tax_pct,
        ROUND(AVG(s.s_tax_percentage), 2) AS avg_store_tax_pct,
        SUM(cc.cc_employees) AS total_cc_employees,
        SUM(s.s_number_employees) AS total_store_employees,
        SUM(cc.cc_sq_ft) AS total_cc_sq_ft,
        SUM(s.s_floor_space) AS total_store_floor_space
    FROM call_center cc
    JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_closed.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_closed.d_year = 2022
      AND s.s_state = cc.cc_state
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_closed.d_date,
        d_open.d_date,
        d_end.d_date
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_state,
    s_store_id,
    s_store_name,
    s_state,
    store_closed_date,
    call_center_open_date,
    promo_start_date,
    promo_end_date,
    promo_count,
    total_promo_cost,
    avg_discounted_promo_cost,
    max_response_target,
    avg_cc_tax_pct,
    avg_store_tax_pct,
    total_cc_employees,
    total_store_employees,
    total_cc_sq_ft,
    total_store_floor_space,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_promo_cost DESC) AS promo_rank
FROM promo_agg
WHERE promo_count > 0
ORDER BY total_promo_cost DESC
LIMIT 100
