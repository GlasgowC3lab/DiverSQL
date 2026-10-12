SELECT
  CASE
    WHEN date_dim.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
    WHEN date_dim.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
    WHEN date_dim.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
    ELSE 'Q4'
  END AS quarter_group,
  (date_dim.d_month_seq % 3) AS month_mod,
  time_dim.t_shift,
  store.s_state,
  COUNT(web_returns.wr_order_number) AS return_orders,
  SUM(web_returns.wr_return_amt) AS total_return_amt,
  SUM(web_returns.wr_net_loss) AS total_net_loss,
  AVG(web_returns.wr_return_quantity) AS avg_return_quantity
FROM date_dim
JOIN web_returns
  ON web_returns.wr_returned_date_sk = date_dim.d_date_sk
JOIN time_dim
  ON web_returns.wr_returned_time_sk = time_dim.t_time_sk
JOIN store
  ON store.s_closed_date_sk = date_dim.d_date_sk
WHERE date_dim.d_year >= 2018
  AND store.s_floor_space > 5000
GROUP BY
  CASE
    WHEN date_dim.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
    WHEN date_dim.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
    WHEN date_dim.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
    ELSE 'Q4'
  END,
  (date_dim.d_month_seq % 3),
  time_dim.t_shift,
  store.s_state
HAVING SUM(web_returns.wr_return_amt) > 5000
ORDER BY total_return_amt DESC
LIMIT 100
