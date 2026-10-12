SELECT
  d.d_year,
  d.d_month_seq,
  w.w_state AS warehouse_state,
  s.s_state AS store_state,
  CASE WHEN w.w_state = s.s_state THEN 'SameState' ELSE 'DifferentState' END AS state_relation,
  COUNT(DISTINCT wr.wr_order_number) AS order_cnt,
  SUM(wr.wr_return_amt) AS total_return_amt,
  SUM(wr.wr_return_quantity) AS total_return_qty,
  SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
  AVG(wr.wr_net_loss) AS avg_net_loss,
  SUM(wr.wr_return_amt) / NULLIF(SUM(i.inv_quantity_on_hand), 0) AS return_per_inventory
FROM date_dim d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY d.d_year, d.d_month_seq, w.w_state, s.s_state,
         CASE WHEN w.w_state = s.s_state THEN 'SameState' ELSE 'DifferentState' END
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY d.d_year, d.d_month_seq, total_return_amt DESC
LIMIT 100
