SELECT
    ca_returning.ca_state AS returning_state,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    ROUND(AVG(wr.wr_return_amt), 2) AS avg_return_amt
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
WHERE td.t_shift = 'Evening'
  AND ca_returning.ca_location_type = 'apartment'
  AND ca_refunded.ca_county = 'Maricopa County'
  AND ca_returning.ca_gmt_offset = -7.00
GROUP BY ca_returning.ca_state
ORDER BY total_net_loss DESC
LIMIT 5
