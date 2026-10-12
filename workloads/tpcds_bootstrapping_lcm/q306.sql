SELECT
    cc.cc_company_name,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d_start.d_year,
    d_start.d_month_seq,
    d_start.d_day_name AS start_day_name,
    d_end.d_day_name AS end_day_name,
    i.inv_item_sk,
    SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
    p.p_promo_name,
    p.p_cost,
    p.p_discount_active,
    COUNT(DISTINCT p.p_promo_id) AS promo_count
FROM date_dim d_start
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_start.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
GROUP BY
    cc.cc_company_name,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d_start.d_year,
    d_start.d_month_seq,
    d_start.d_day_name,
    d_end.d_day_name,
    i.inv_item_sk,
    p.p_promo_name,
    p.p_cost,
    p.p_discount_active
ORDER BY total_qty_on_hand DESC
LIMIT 100
