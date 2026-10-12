WITH catalog_agg AS (
  SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(*) AS catalog_return_cnt,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    AVG(cr.cr_return_amount) AS catalog_avg_return_amount
  FROM catalog_returns cr
  JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100
  GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
  HAVING COUNT(*) > 5
),
store_agg AS (
  SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(*) AS store_return_cnt,
    SUM(sr.sr_net_loss) AS store_net_loss,
    AVG(sr.sr_return_amt) AS store_avg_return_amount
  FROM store_returns sr
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2451000 AND 2451100
  GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
  HAVING COUNT(*) > 5
)
SELECT
  COALESCE(ca.cd_demo_sk, sa.cd_demo_sk) AS demo_sk,
  COALESCE(ca.cd_gender, sa.cd_gender) AS gender,
  COALESCE(ca.cd_marital_status, sa.cd_marital_status) AS marital_status,
  COALESCE(ca.cd_education_status, sa.cd_education_status) AS education_status,
  COALESCE(ca.catalog_return_cnt, 0) AS catalog_return_cnt,
  COALESCE(sa.store_return_cnt, 0) AS store_return_cnt,
  COALESCE(ca.catalog_net_loss, 0) AS catalog_net_loss,
  COALESCE(sa.store_net_loss, 0) AS store_net_loss,
  COALESCE(ca.catalog_avg_return_amount, 0) AS catalog_avg_return_amount,
  COALESCE(sa.store_avg_return_amount, 0) AS store_avg_return_amount
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
  ON ca.cd_demo_sk = sa.cd_demo_sk
ORDER BY catalog_net_loss DESC
LIMIT 100
