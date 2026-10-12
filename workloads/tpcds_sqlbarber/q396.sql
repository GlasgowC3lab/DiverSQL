SELECT
    date_dim.d_year,
    date_dim.d_month_seq,
    time_dim.t_hour,
    SUM(web_returns.wr_return_amt) AS total_return_amount,
    SUM(web_returns.wr_net_loss) AS total_net_loss
FROM web_returns
JOIN date_dim ON web_returns.wr_returned_date_sk = date_dim.d_date_sk
JOIN time_dim ON web_returns.wr_returned_time_sk = time_dim.t_time_sk
WHERE date_dim.d_year = 1923
  AND time_dim.t_hour BETWEEN 17 AND 4
GROUP BY date_dim.d_year, date_dim.d_month_seq, time_dim.t_hour
HAVING SUM(web_returns.wr_return_amt) > 733.60
ORDER BY total_return_amount DESC
