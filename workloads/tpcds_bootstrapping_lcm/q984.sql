SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    p.p_promo_name AS promotion_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_holiday,
    d_ret.d_date AS return_date,
    d_cc_closed.d_date AS call_center_closed_date,
    d_cc_open.d_date AS call_center_open_date,
    d_promo_end.d_date AS promotion_end_date,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    CASE
        WHEN SUM(cr.cr_return_quantity) > 0 THEN SUM(cr.cr_return_amount) / SUM(cr.cr_return_quantity)
        ELSE NULL
    END AS avg_return_amount_per_item
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_date_sk <= p.p_end_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_holiday,
    d_ret.d_date,
    d_cc_closed.d_date,
    d_cc_open.d_date,
    d_promo_end.d_date
ORDER BY total_net_loss DESC
LIMIT 100
