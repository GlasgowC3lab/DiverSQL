SELECT
  agg.s_store_name,
  agg.store_city,
  agg.return_year,
  agg.return_month,
  agg.r_reason_desc,
  agg.refunded_city,
  agg.returning_city,
  agg.total_returns,
  agg.total_return_amount,
  agg.total_net_loss,
  agg.avg_return_amount,
  agg.total_fee,
  agg.total_tax,
  RANK() OVER (PARTITION BY agg.s_store_name ORDER BY agg.total_net_loss DESC) AS reason_loss_rank
FROM (
  SELECT
    s.s_store_name,
    s.s_city AS store_city,
    d.d_year AS return_year,
    d.d_moy AS return_month,
    r.r_reason_desc,
    ca_ref.ca_city AS refunded_city,
    ca_ret.ca_city AS returning_city,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  GROUP BY
    s.s_store_name,
    s.s_city,
    d.d_year,
    d.d_moy,
    r.r_reason_desc,
    ca_ref.ca_city,
    ca_ret.ca_city
) agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
