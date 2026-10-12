SELECT
  d.d_year,
  d.d_month_seq,
  (d.d_year * 100 + d.d_month_seq) AS year_month,
  CASE WHEN (d.d_year % 2) = 0 THEN 'EvenYear' ELSE 'OddYear' END AS year_parity,
  w.w_city,
  s.s_state,
  SUM(cr.cr_net_loss) AS catalog_net_loss,
  SUM(wr.wr_net_loss) AS web_net_loss,
  SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_net_loss,
  SUM(cr.cr_return_quantity) AS catalog_return_qty,
  SUM(wr.wr_return_quantity) AS web_return_qty,
  SUM(cr.cr_return_quantity + wr.wr_return_quantity) AS total_return_qty,
  AVG(cr.cr_fee) AS avg_catalog_fee,
  AVG(wr.wr_fee) AS avg_web_fee,
  SUM(cr.cr_return_amount) AS catalog_return_amount,
  SUM(wr.wr_return_amt_inc_tax) AS web_return_amount_inc_tax,
  COUNT(DISTINCT cr.cr_item_sk) AS distinct_catalog_items,
  COUNT(DISTINCT wr.wr_item_sk) AS distinct_web_items,
  (SUM(cr.cr_net_loss + wr.wr_net_loss) / NULLIF(SUM(cr.cr_return_quantity + wr.wr_return_quantity), 0)) AS net_loss_per_qty
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY
  d.d_year,
  d.d_month_seq,
  (d.d_year * 100 + d.d_month_seq),
  CASE WHEN (d.d_year % 2) = 0 THEN 'EvenYear' ELSE 'OddYear' END,
  w.w_city,
  s.s_state
ORDER BY total_net_loss DESC
LIMIT 100
