WITH demo_pair_agg AS (
  SELECT
    cd_ret.cd_marital_status AS returning_marital,
    cd_ret.cd_gender AS returning_gender,
    cd_ref.cd_marital_status AS refunded_marital,
    cd_ref.cd_gender AS refunded_gender,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS num_returns,
    AVG(cr.cr_fee) AS avg_fee
  FROM catalog_returns cr
  JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  GROUP BY
    cd_ret.cd_marital_status,
    cd_ret.cd_gender,
    cd_ref.cd_marital_status,
    cd_ref.cd_gender
)
SELECT
  returning_marital,
  returning_gender,
  refunded_marital,
  refunded_gender,
  total_return_amount,
  num_returns,
  avg_fee,
  CASE
    WHEN total_return_amount < 1000 THEN 'Low'
    WHEN total_return_amount BETWEEN 1000 AND 5000 THEN 'Medium'
    ELSE 'High'
  END AS amount_category,
  DENSE_RANK() OVER (ORDER BY total_return_amount DESC) AS amount_rank
FROM demo_pair_agg
WHERE total_return_amount > 0
ORDER BY amount_rank
LIMIT 20
