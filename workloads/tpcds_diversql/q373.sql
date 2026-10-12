SELECT
  cd.cd_gender,
  cd.cd_marital_status,
  SUM(ss.ss_net_paid_inc_tax) AS total_paid,
  COUNT(*) AS txn_cnt
FROM
  store_sales ss
JOIN
  customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE
  cd.cd_gender = 'M'
  AND ss.ss_net_paid_inc_tax > 1000
GROUP BY
  cd.cd_gender,
  cd.cd_marital_status
