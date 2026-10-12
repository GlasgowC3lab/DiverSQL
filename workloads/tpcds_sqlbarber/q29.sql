SELECT cd.cd_gender,
       SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status = 'M'
GROUP BY cd.cd_gender
