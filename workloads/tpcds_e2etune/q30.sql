WITH agg AS (
  SELECT
    r.r_reason_id,
    r.r_reason_desc,
    SUM(wr.wr_return_quantity) AS total_qty,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
    AND r.r_reason_desc IN ('Package was damaged', 'Stopped working')
  GROUP BY r.r_reason_id, r.r_reason_desc
  HAVING SUM(wr.wr_return_quantity) > 0
)
SELECT
  a.r_reason_id,
  a.r_reason_desc,
  a.total_qty,
  a.total_return_amt,
  a.avg_return_amt,
  a.total_net_loss,
  a.total_refunded_cash,
  a.return_cnt,
  (a.total_refunded_cash / NULLIF(a.total_net_loss, 0)) AS refunded_cash_ratio,
  RANK() OVER (ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM agg a
ORDER BY net_loss_rank
LIMIT 5
