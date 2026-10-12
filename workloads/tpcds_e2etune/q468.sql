SELECT
    ca_ret.ca_state AS returning_state,
    ca_ref.ca_city AS refunded_city,
    COUNT(*) AS num_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_fee) AS total_fee
FROM web_returns wr
JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
WHERE ca_ret.ca_state IN ('AZ', 'CO')
  AND ca_ref.ca_zip LIKE '8%'
  AND wr.wr_returned_date_sk BETWEEN 20230101 AND 20231231
GROUP BY ca_ret.ca_state, ca_ref.ca_city
HAVING SUM(wr.wr_net_loss) > 10000
ORDER BY total_net_loss DESC
LIMIT 50
