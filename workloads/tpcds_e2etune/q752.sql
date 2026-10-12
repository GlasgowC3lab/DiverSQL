WITH agg AS (
  SELECT
    ca_refund.ca_state AS refund_state,
    ca_refund.ca_county AS refund_county,
    ca_return.ca_state AS return_state,
    ca_return.ca_county AS return_county,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    AVG(wr.wr_return_quantity) AS avg_return_quantity
  FROM web_returns wr
  JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
  JOIN customer_address ca_return
    ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
  WHERE wr.wr_returned_date_sk >= 20200101
    AND ca_refund.ca_state IN ('AZ', 'NM', 'PA')
  GROUP BY
    ca_refund.ca_state,
    ca_refund.ca_county,
    ca_return.ca_state,
    ca_return.ca_county
  HAVING SUM(wr.wr_return_amt) > 5000
)
SELECT
  refund_state,
  refund_county,
  return_state,
  return_county,
  num_returns,
  total_return_amount,
  avg_return_tax,
  avg_return_quantity,
  RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
