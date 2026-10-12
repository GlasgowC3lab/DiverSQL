SELECT
  s.s_store_id,
  s.s_city,
  d.d_year,
  i.i_category,
  ca_returning.ca_state AS returning_state,
  ca_refunded.ca_state AS refunded_state,
  (i.i_current_price - i.i_wholesale_cost) AS price_margin,
  COUNT(*) AS return_count,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_net_loss) AS total_net_loss,
  SUM(wr.wr_return_quantity) AS total_quantity,
  AVG(wr.wr_return_amt) AS avg_return_amount
FROM web_returns wr
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
JOIN customer_address ca_refunded
  ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
  ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
  s.s_store_id,
  s.s_city,
  d.d_year,
  i.i_category,
  ca_returning.ca_state,
  ca_refunded.ca_state,
  (i.i_current_price - i.i_wholesale_cost)
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
