SELECT
  d.d_year AS return_year,
  d.d_quarter_name AS return_quarter,
  s.s_state,
  cd_refunded.cd_gender AS refunded_gender,
  cd_returning.cd_gender AS returning_gender,
  wp.wp_type,
  CASE
    WHEN cr.cr_net_loss > 100 THEN 'high_loss'
    WHEN cr.cr_net_loss > 0   THEN 'moderate_loss'
    ELSE 'no_loss'
  END AS loss_category,
  COUNT(*) AS num_returns,
  SUM(cr.cr_net_loss) AS total_net_loss,
  AVG(cr.cr_fee) AS avg_fee,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
  AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
GROUP BY
  d.d_year,
  d.d_quarter_name,
  s.s_state,
  cd_refunded.cd_gender,
  cd_returning.cd_gender,
  wp.wp_type,
  CASE
    WHEN cr.cr_net_loss > 100 THEN 'high_loss'
    WHEN cr.cr_net_loss > 0   THEN 'moderate_loss'
    ELSE 'no_loss'
  END
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
