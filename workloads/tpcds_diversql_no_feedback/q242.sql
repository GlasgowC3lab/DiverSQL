SELECT
    cd.cd_gender,
    cd.cd_credit_rating,
    SUM(sr.sr_store_credit) AS total_store_credit
FROM store_returns sr
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Good'
  AND sr.sr_store_credit > 20.00
GROUP BY cd.cd_gender, cd.cd_credit_rating
ORDER BY total_store_credit DESC
LIMIT 10
