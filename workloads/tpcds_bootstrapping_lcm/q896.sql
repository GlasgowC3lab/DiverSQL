SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_ret.d_year AS return_year,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    cc.cc_state AS cc_state,
    s.s_state AS store_state,
    ca_refunded.ca_state AS refunded_state,
    ca_returning.ca_state AS returning_state,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_quantity) AS total_quantity,
    CASE 
        WHEN SUM(cr.cr_refunded_cash) > 0 THEN SUM(cr.cr_return_amount) / SUM(cr.cr_refunded_cash)
        ELSE NULL
    END AS return_to_refund_ratio,
    CASE 
        WHEN SUM(cr.cr_return_amount) > SUM(cr.cr_refunded_cash) THEN 'Loss'
        ELSE 'Gain'
    END AS profit_status,
    CASE 
        WHEN cc.cc_state = 'CA' THEN 'CA'
        ELSE 'Other'
    END AS cc_state_group
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_ret.d_year,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    cc.cc_state,
    s.s_state,
    ca_refunded.ca_state,
    ca_returning.ca_state
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
