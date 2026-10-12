SELECT
    cc.cc_manager,
    cc.cc_city,
    cc.cc_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_quarter_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    t.t_shift,
    t.t_meal_time,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    COUNT(*) AS return_count,
    AVG(wr.wr_fee) AS avg_fee,
    AVG(date_diff('day', d_cc_open.d_date, d_ret.d_date)) AS avg_days_since_open
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_ret.d_year = 2020
  AND t.t_shift = 'Evening'
GROUP BY
    cc.cc_manager,
    cc.cc_city,
    cc.cc_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_quarter_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    t.t_shift,
    t.t_meal_time
ORDER BY total_return_amount DESC
LIMIT 100
