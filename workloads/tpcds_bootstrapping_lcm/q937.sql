SELECT
    cc.cc_call_center_id,
    cc.cc_city AS call_center_city,
    s.s_store_name,
    s.s_city AS store_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS total_returns,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    MAX(cr.cr_return_amount) AS max_return_amount,
    ca_refund.ca_state AS refunded_state,
    ca_return.ca_state AS returning_state,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
    ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    ca_refund.ca_state,
    ca_return.ca_state,
    d_cc_closed.d_year,
    d_cc_open.d_year
ORDER BY total_net_loss DESC
LIMIT 100
