SELECT
    cc.cc_call_center_id,
    cc.cc_name AS call_center_name,
    cc.cc_manager,
    cc.cc_gmt_offset,
    d_cc_open.d_date AS call_center_open_date,
    d_ret.d_date AS return_date,
    date_diff('day', d_cc_open.d_date, d_ret.d_date) AS days_since_cc_open,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_floor_space,
    cd_ret.cd_gender AS returning_customer_gender,
    cd_ret.cd_marital_status AS returning_customer_marital_status,
    cd_ref.cd_credit_rating AS refunded_customer_credit_rating,
    cd_ref.cd_education_status AS refunded_customer_education_status,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_quantity) AS total_return_quantity
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_manager,
    cc.cc_gmt_offset,
    d_cc_open.d_date,
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    cd_ref.cd_credit_rating,
    cd_ref.cd_education_status
ORDER BY total_return_amount DESC
LIMIT 100
