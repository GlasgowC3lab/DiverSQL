SELECT rc.c_birth_month,
       t.t_hour,
       rc.c_current_hdemo_sk,
       COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
       SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
       SUM(wr.wr_net_loss) AS total_net_loss,
       AVG(wr.wr_return_quantity) AS avg_return_quantity
FROM web_returns wr
JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
JOIN customer rc ON wr.wr_refunded_customer_sk = rc.c_customer_sk
JOIN customer rcn ON wr.wr_returning_customer_sk = rcn.c_customer_sk
WHERE rc.c_birth_month IN (4, 10, 7)
  AND rc.c_current_hdemo_sk IN (3784, 7120)
  AND t.t_hour BETWEEN 9 AND 17
  AND wr.wr_return_quantity > 1
GROUP BY rc.c_birth_month, t.t_hour, rc.c_current_hdemo_sk
HAVING SUM(wr.wr_return_amt_inc_tax) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
