SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_tax) AS total_tax,
    SUM(CASE WHEN ca_ref.ca_city = s.s_city THEN 1 ELSE 0 END) AS refunds_same_city_as_store,
    SUM(CASE WHEN ca_ref.ca_state = s.s_state THEN 1 ELSE 0 END) AS refunds_same_state_as_store,
    MIN(date_diff('day', d_cc_open.d_date, d_ret.d_date)) AS min_days_since_cc_open,
    MAX(date_diff('day', d_cc_closed.d_date, d_ret.d_date)) AS max_days_since_cc_closed
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
