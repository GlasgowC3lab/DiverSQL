SELECT
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq AS month,
    cc.cc_name AS call_center_name,
    p.p_promo_name AS promotion_name,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_item_sk) AS distinct_items_returned,
    AVG(p.p_cost) AS avg_promotion_cost,
    SUM(p.p_cost) AS total_promotion_cost,
    MAX(cc.cc_employees) AS max_call_center_employees,
    SUM(sr.sr_return_tax) AS total_return_tax,
    SUM(sr.sr_store_credit) AS total_store_credit,
    SUM(sr.sr_return_quantity) AS total_return_quantity
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    cc.cc_name,
    p.p_promo_name
ORDER BY total_return_amount DESC
LIMIT 100
