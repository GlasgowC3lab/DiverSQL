SELECT
    rc.c_birth_country AS returning_country,
    fc.c_birth_country AS refunded_country,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_net_loss) / COUNT(*) AS avg_net_loss_per_return,
    RANK() OVER (PARTITION BY rc.c_birth_country ORDER BY SUM(wr.wr_net_loss) DESC) AS net_loss_rank
FROM web_returns wr
JOIN customer rc
  ON wr.wr_returning_customer_sk = rc.c_customer_sk
JOIN customer fc
  ON wr.wr_refunded_customer_sk = fc.c_customer_sk
WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
  AND wr.wr_return_quantity > 0
  AND rc.c_preferred_cust_flag = 'Y'
GROUP BY rc.c_birth_country, fc.c_birth_country
HAVING SUM(wr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
