WITH aggregated AS (
  SELECT
    t.t_hour,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    COUNT(*) AS num_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_fee) AS total_fee
  FROM web_returns wr
  JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
  JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  WHERE cd_ret.cd_credit_rating = 'High Risk'
    AND cd_ret.cd_gender = 'F'
    AND cd_ref.cd_credit_rating = 'Low Risk'
    AND t.t_shift = 'Evening'
  GROUP BY t.t_hour, cd_ret.cd_gender, cd_ret.cd_marital_status
  HAVING COUNT(*) >= 5
)
SELECT
  t_hour,
  cd_gender,
  cd_marital_status,
  num_returns,
  total_net_loss,
  avg_return_amount,
  total_quantity,
  total_fee,
  RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_loss DESC) AS loss_rank_by_hour
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 50
