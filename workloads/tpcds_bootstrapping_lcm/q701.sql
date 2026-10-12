SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_quarter_name,
    ca_ret.ca_city AS returning_city,
    ca_ref.ca_city AS refunded_city,
    COUNT(*) AS num_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    (SUM(wr.wr_net_loss) / NULLIF(COUNT(*), 0)) AS avg_net_loss_per_return
FROM web_returns wr
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_ret
  ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
  ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_quarter_name,
    ca_ret.ca_city,
    ca_ref.ca_city
ORDER BY total_net_loss DESC
LIMIT 50
