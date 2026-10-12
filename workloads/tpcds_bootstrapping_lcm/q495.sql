SELECT
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    cc.cc_employees,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_closed.d_month_seq AS cc_closed_month,
    d_cc_open.d_year AS cc_open_year,
    d_cc_open.d_month_seq AS cc_open_month,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    ca_ref.ca_city AS refunded_city,
    ca_ret.ca_city AS returning_city,
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_fee) AS avg_fee,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year = 2022
GROUP BY
    cc.cc_name,
    cc.cc_state,
    cc.cc_employees,
    d_cc_closed.d_year,
    d_cc_closed.d_month_seq,
    d_cc_open.d_year,
    d_cc_open.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca_ref.ca_city,
    ca_ret.ca_city,
    d_return.d_year,
    d_return.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
