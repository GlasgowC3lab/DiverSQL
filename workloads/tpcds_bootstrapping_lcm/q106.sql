SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date,
    s.s_store_sk,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_store_closed.d_date AS store_closed_date,
    d_return.d_year,
    d_return.d_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    MAX(cr.cr_return_amount) AS max_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_return.d_year = 2001
  AND cc.cc_state = 'CA'
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d_cc_open.d_date,
    d_cc_closed.d_date,
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store_closed.d_date,
    d_return.d_year,
    d_return.d_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    d_promo_start.d_date,
    d_promo_end.d_date
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
