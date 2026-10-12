SELECT
    cc.cc_division_name,
    s.s_state,
    i.i_category,
    (d_ret.d_year * 100 + d_ret.d_month_seq) AS year_month_key,
    CASE WHEN i.i_wholesale_cost > 100 THEN 'High' ELSE 'Low' END AS cost_bucket,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_amt_inc_tax) AS total_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_quantity) AS total_quantity,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    SUM(wr.wr_return_amt) / NULLIF(cc.cc_employees, 0) AS return_per_employee,
    AVG(date_diff('day', d_cc_open.d_date, d_ret.d_date)) AS avg_days_since_cc_open
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_ret.d_year >= 2020
GROUP BY
    cc.cc_division_name,
    s.s_state,
    i.i_category,
    (d_ret.d_year * 100 + d_ret.d_month_seq),
    CASE WHEN i.i_wholesale_cost > 100 THEN 'High' ELSE 'Low' END,
    cc.cc_employees
ORDER BY total_return_amount DESC
LIMIT 100
