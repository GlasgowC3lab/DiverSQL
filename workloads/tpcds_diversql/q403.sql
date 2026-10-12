SELECT
    td.t_hour,
    td.t_am_pm,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    AVG(wr.wr_refunded_cash) AS avg_refunded_cash
FROM web_returns wr
JOIN time_dim td
    ON wr.wr_returned_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND wr.wr_return_amt_inc_tax > 500
GROUP BY td.t_hour, td.t_am_pm
ORDER BY td.t_hour
