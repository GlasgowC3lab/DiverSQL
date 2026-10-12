SELECT
  d_ret.d_year,
  s.s_state,
  CASE
    WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
    WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
    ELSE 'Other'
  END AS region,
  COUNT(DISTINCT sr.sr_ticket_number) AS store_return_transactions,
  COUNT(DISTINCT wr.wr_order_number) AS web_return_transactions,
  SUM(sr.sr_net_loss) AS total_store_net_loss,
  SUM(wr.wr_net_loss) AS total_web_net_loss,
  SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) AS total_return_amount,
  AVG(sr.sr_return_quantity) AS avg_store_return_qty,
  AVG(wr.wr_return_quantity) AS avg_web_return_qty,
  SUM(CASE WHEN d_ret.d_month_seq BETWEEN 1 AND 3 THEN sr.sr_net_loss ELSE 0 END) AS q1_store_net_loss,
  SUM(CASE WHEN d_ret.d_month_seq BETWEEN 4 AND 6 THEN wr.wr_net_loss ELSE 0 END) AS q2_web_net_loss,
  MIN(d_cl.d_date) AS store_closed_date_min,
  MAX(d_cl.d_date) AS store_closed_date_max
FROM date_dim d_ret
JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_cl ON s.s_closed_date_sk = d_cl.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
GROUP BY
  d_ret.d_year,
  s.s_state,
  CASE
    WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
    WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
    ELSE 'Other'
  END
HAVING SUM(sr.sr_net_loss) > 0
ORDER BY d_ret.d_year DESC, total_store_net_loss DESC
LIMIT 100
