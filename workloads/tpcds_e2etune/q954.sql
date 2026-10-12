WITH high_loss_customers AS (
    SELECT
        wr.wr_returning_customer_sk AS cust_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
    HAVING SUM(wr.wr_net_loss) > 10000
)
SELECT
    ca_ret.ca_state AS returning_state,
    td.t_shift AS shift,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    COUNT(DISTINCT hlc.cust_sk) AS high_loss_customer_cnt
FROM web_returns wr
JOIN time_dim td
  ON wr.wr_returned_time_sk = td.t_time_sk
JOIN customer c_ret
  ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_address ca_ret
  ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN high_loss_customers hlc
  ON hlc.cust_sk = c_ret.c_customer_sk
WHERE c_ret.c_preferred_cust_flag = 'Y'
  AND ca_ret.ca_country = 'United States'
GROUP BY ca_ret.ca_state, td.t_shift
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
