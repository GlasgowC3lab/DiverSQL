SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
FROM web_returns wr
JOIN customer_address ca
    ON wr.wr_returning_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -6.00
  AND wr.wr_return_amt_inc_tax > 500
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_return_amount DESC
LIMIT 10
