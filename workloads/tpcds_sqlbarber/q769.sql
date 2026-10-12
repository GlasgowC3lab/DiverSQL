SELECT cd.cd_gender, SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_sold_date_sk = 2450835
GROUP BY cd.cd_gender
