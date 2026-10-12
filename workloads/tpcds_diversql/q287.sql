SELECT
  cd.cd_demo_sk,
  cd.cd_credit_rating,
  SUM(wr.wr_reversed_charge) AS total_reversed_charge,
  COUNT(*) AS return_cnt
FROM web_returns AS wr
JOIN customer_demographics AS cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'High Risk'
  AND wr.wr_reversed_charge > 100.00
GROUP BY cd.cd_demo_sk, cd.cd_credit_rating
ORDER BY total_reversed_charge DESC
LIMIT 20
