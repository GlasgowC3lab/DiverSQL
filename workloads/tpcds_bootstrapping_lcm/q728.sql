SELECT
    cc.cc_name,
    cc.cc_market_manager,
    cc.cc_division,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    AVG(date_diff('day', d_cc_open.d_date, d_ret.d_date)) AS avg_days_since_open,
    AVG(date_diff('day', d_ret.d_date, d_cc_closed.d_date)) AS avg_days_until_closed,
    SUM(s.s_floor_space) AS total_store_floor_space,
    GROUPING(cc.cc_name) AS g_cc,
    GROUPING(s.s_state) AS g_state,
    GROUPING(d_ret.d_year) AS g_year,
    GROUPING(d_ret.d_month_seq) AS g_month
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY ROLLUP (cc.cc_name, s.s_state, d_ret.d_year, d_ret.d_month_seq, cc.cc_market_manager, cc.cc_division)
HAVING SUM(cr.cr_return_amount) > 10000
