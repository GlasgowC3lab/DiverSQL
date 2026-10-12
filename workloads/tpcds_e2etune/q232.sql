WITH returns_agg AS (
  SELECT
    cp.cp_type,
    s.s_state,
    DATE_TRUNC('quarter', dr.d_date) AS quarter,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss
  FROM store_returns sr
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
  JOIN catalog_page cp
    ON 1 = 1
  JOIN date_dim cp_start
    ON cp.cp_start_date_sk = cp_start.d_date_sk
  JOIN date_dim cp_end
    ON cp.cp_end_date_sk = cp_end.d_date_sk
  WHERE dr.d_date_sk BETWEEN cp_start.d_date_sk AND cp_end.d_date_sk
    AND dr.d_year = 2001
    AND s.s_state IN ('CA', 'NY', 'TX')
  GROUP BY cp.cp_type, s.s_state, DATE_TRUNC('quarter', dr.d_date)
  HAVING SUM(sr.sr_return_amt) > 10000
)
SELECT
  cp_type,
  s_state,
  quarter,
  num_returns,
  total_return_amount,
  avg_return_amount,
  total_net_loss,
  RANK() OVER (PARTITION BY quarter ORDER BY total_return_amount DESC) AS return_amount_rank
FROM returns_agg
ORDER BY total_return_amount DESC
LIMIT 20
