WITH unified_returns AS (
  SELECT
    sr.sr_returned_date_sk AS returned_date_sk,
    sr.sr_net_loss AS net_loss,
    sr.sr_return_amt_inc_tax AS return_amt_inc_tax,
    sr.sr_return_quantity AS return_quantity,
    ca.ca_state,
    hd.hd_income_band_sk
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451000
  UNION ALL
  SELECT
    wr.wr_returned_date_sk AS returned_date_sk,
    wr.wr_net_loss AS net_loss,
    wr.wr_return_amt_inc_tax AS return_amt_inc_tax,
    wr.wr_return_quantity AS return_quantity,
    ca.ca_state,
    hd.hd_income_band_sk
  FROM web_returns wr
  JOIN customer c_ref ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450900 AND 2451000
),
aggregated AS (
  SELECT
    ca_state,
    hd_income_band_sk,
    SUM(return_amt_inc_tax) AS total_return_amount,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(return_quantity) AS avg_quantity
  FROM unified_returns
  GROUP BY ca_state, hd_income_band_sk
  HAVING SUM(return_amt_inc_tax) > 1000
)
SELECT
  ca_state,
  hd_income_band_sk,
  total_return_amount,
  total_net_loss,
  return_cnt,
  avg_quantity,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 20
