SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    s.s_store_name,
    s.s_state AS store_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ret.cd_gender AS returning_gender,
    cd_ret.cd_marital_status AS returning_marital_status,
    cd_ref.cd_gender AS refunded_gender,
    cd_ref.cd_marital_status AS refunded_marital_status,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc.d_date_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2002
GROUP BY
    cc.cc_call_center_id,
    cc.cc_state,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    cd_ref.cd_gender,
    cd_ref.cd_marital_status
ORDER BY total_net_loss DESC
LIMIT 100
