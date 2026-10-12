SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    cc.cc_state AS call_center_state,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    dd_ret.d_date AS return_date,
    dd_ret.d_year,
    dd_ret.d_month_seq,
    dd_ret.d_day_name,
    p.p_promo_name,
    p.p_discount_active,
    p.p_cost,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_amount_inc_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    CASE
        WHEN dd_ret.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN dd_ret.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN dd_ret.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter_label,
    ROUND(SUM(cr.cr_return_amount) / NULLIF(p.p_cost, 0), 2) AS return_to_promo_cost_ratio
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dd_ret
    ON cr.cr_returned_date_sk = dd_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_ret.d_date_sk
JOIN date_dim dd_cc_closed
    ON cc.cc_closed_date_sk = dd_cc_closed.d_date_sk
JOIN date_dim dd_cc_open
    ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = dd_ret.d_date_sk
JOIN date_dim dd_promo_end
    ON p.p_end_date_sk = dd_promo_end.d_date_sk
WHERE dd_ret.d_year = 2022
  AND cc.cc_state = s.s_state
  AND p.p_discount_active = 'Y'
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    s.s_state,
    dd_ret.d_date,
    dd_ret.d_year,
    dd_ret.d_month_seq,
    dd_ret.d_day_name,
    p.p_promo_name,
    p.p_discount_active,
    p.p_cost
ORDER BY total_return_amount DESC
LIMIT 100
