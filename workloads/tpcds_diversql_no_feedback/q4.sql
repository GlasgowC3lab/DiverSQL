SELECT
  cd_gender,
  cd_marital_status,
  AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM tpcds.customer_demographics
WHERE cd_gender = 'F'
  AND cd_education_status = '4 yr Degree         '
GROUP BY cd_gender, cd_marital_status
ORDER BY avg_purchase_estimate DESC
LIMIT 10
