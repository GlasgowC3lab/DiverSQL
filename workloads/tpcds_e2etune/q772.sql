WITH agg AS (
  SELECT
    cc.cc_class,
    td.t_hour,
    cd_ret.cd_gender,
    cd_ret.cd_education_status,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  WHERE cc.cc_rec_end_date > DATE '2000-01-01'
    AND cc.cc_class IN ('large', 'medium')
    AND td.t_hour BETWEEN 9 AND 17
    AND cr.cr_net_loss > 0
  GROUP BY
    cc.cc_class,
    td.t_hour,
    cd_ret.cd_gender,
    cd_ret.cd_education_status
  HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
  cc_class,
  t_hour,
  cd_gender,
  cd_education_status,
  total_net_loss,
  total_return_amount,
  avg_return_amount,
  return_cnt,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
