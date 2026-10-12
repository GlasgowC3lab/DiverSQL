SELECT
    d_cc_closed.d_year AS year,
    d_cc_closed.d_quarter_name AS quarter,
    cc.cc_division,
    s.s_state,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr.wr_return_amt_inc_tax) - SUM(wr.wr_return_tax) AS net_return_excluding_tax,
    SUM(wr.wr_fee * wr.wr_return_quantity) AS total_fee,
    COUNT(*) AS return_cnt,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(date_diff('day', d_cc_open.d_date, d_cc_closed.d_date)) AS avg_open_to_close_days
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_cc_closed.d_date_sk
GROUP BY
    d_cc_closed.d_year,
    d_cc_closed.d_quarter_name,
    cc.cc_division,
    s.s_state
ORDER BY
    d_cc_closed.d_year,
    d_cc_closed.d_quarter_name,
    cc.cc_division,
    s.s_state
LIMIT 100
