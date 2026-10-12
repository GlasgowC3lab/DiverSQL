SELECT i.i_category,
       i.i_color,
       SUM(wr.wr_net_loss) AS total_net_loss,
       SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
       AVG(wr.wr_return_quantity) AS avg_return_qty,
       COUNT(*) AS num_returns,
       RANK() OVER (ORDER BY SUM(wr.wr_net_loss) DESC) AS loss_rank
FROM web_returns wr
JOIN item i ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_rec_start_date <= DATE '2023-01-01'
  AND i.i_rec_end_date   >= DATE '2023-01-01'
  AND wr.wr_returned_date_sk BETWEEN 20220101 AND 20231231
  AND i.i_manager_id IN (6, 18, 27)
GROUP BY i.i_category, i.i_color
HAVING SUM(wr.wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 10
