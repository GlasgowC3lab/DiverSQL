SELECT
    ca.ca_state,
    td.t_hour,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amt,
    SUM(CASE WHEN wr.wr_return_amt > 200 THEN wr.wr_return_amt ELSE 0 END) AS high_value_return_sum,
    RANK() OVER (ORDER BY SUM(wr.wr_net_loss) DESC) AS net_loss_rank
FROM web_returns AS wr
JOIN time_dim AS td
  ON wr.wr_returned_time_sk = td.t_time_sk
JOIN customer AS c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address AS ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE c.c_birth_month IN (4, 12, 10)
  AND c.c_birth_country = 'IRELAND'
  AND td.t_hour BETWEEN 9 AND 18
GROUP BY ca.ca_state, td.t_hour
HAVING SUM(wr.wr_return_quantity) > 0
ORDER BY total_net_loss DESC
LIMIT 50
