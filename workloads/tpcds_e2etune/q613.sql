SELECT
    t.t_hour AS hour_of_day,
    ca.ca_state AS customer_state,
    COUNT(*) AS total_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN c.c_birth_year < 1970 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_birth_before_1970,
    (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2) AS overall_avg_net_loss,
    RANK() OVER (PARTITION BY t.t_hour ORDER BY SUM(sr.sr_net_loss) DESC) AS net_loss_state_rank
FROM store_returns sr
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_returned_date_sk BETWEEN 20200101 AND 20201231
  AND ca.ca_country = 'United States'
GROUP BY t.t_hour, ca.ca_state
HAVING COUNT(*) >= 20
ORDER BY t.t_hour, total_net_loss DESC
LIMIT 100
