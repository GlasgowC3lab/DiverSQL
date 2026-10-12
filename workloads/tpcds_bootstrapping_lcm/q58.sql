SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_tax) AS total_return_tax,
    DATE_DIFF('day', d_cc_open.d_date, d_ret.d_date) AS days_since_open_to_return,
    DATE_DIFF('month', d_cc_closed.d_date, d_ret.d_date) AS months_between_cc_closed_and_store_closed,
    CASE WHEN SUM(cr.cr_return_amount) > 100000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_ret.d_year BETWEEN 2018 AND 2020
  AND s.s_state = cc.cc_state
  AND w.w_state = s.s_state
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_cc_open.d_date,
    d_cc_closed.d_date,
    d_ret.d_date
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY total_return_amount DESC
LIMIT 100
