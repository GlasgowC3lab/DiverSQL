SELECT
    cc.cc_country,
    s.s_state,
    i.i_category,
    d_cc_closed.d_year,
    d_cc_closed.d_month_seq,
    p.p_promo_name,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT cc.cc_call_center_sk) AS distinct_call_centers,
    COUNT(DISTINCT s.s_store_sk) AS distinct_stores,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS discount_active_cost,
    COUNT(*) AS total_rows
FROM call_center cc
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN promotion p
  ON p.p_start_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_p_end
  ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN item i
  ON p.p_item_sk = i.i_item_sk
JOIN store s
  ON s.s_closed_date_sk = d_cc_closed.d_date_sk
GROUP BY ROLLUP (
    cc.cc_country,
    s.s_state,
    i.i_category,
    d_cc_closed.d_year,
    d_cc_closed.d_month_seq,
    p.p_promo_name
)
LIMIT 100
