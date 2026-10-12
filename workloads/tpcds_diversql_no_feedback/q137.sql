WITH max_ship_tax AS (
   SELECT MAX(cs_net_paid_inc_tax) AS max_val
   FROM catalog_sales
   WHERE cs_ship_hdemo_sk = 4563
)
SELECT
   cs_bill_customer_sk AS customer_key,
   cd_gender,
   CASE WHEN cd_education_status = 'College' THEN 'College' ELSE 'NonCollege' END AS edu_category,
   COUNT(DISTINCT cs_item_sk) AS distinct_item_count,
   SUM(DISTINCT cs_coupon_amt) AS distinct_coupon_sum,
   cs_net_paid_inc_tax
FROM catalog_sales
JOIN customer_demographics
   ON catalog_sales.cs_bill_cdemo_sk = customer_demographics.cd_demo_sk
WHERE cs_net_paid_inc_tax > (SELECT max_val FROM max_ship_tax)
  AND cd_dep_employed_count >= 2
GROUP BY cs_bill_customer_sk, cd_gender, cd_education_status, cs_net_paid_inc_tax

UNION ALL

SELECT
   cs_ship_customer_sk AS customer_key,
   cd_gender,
   CASE WHEN cd_education_status = 'College' THEN 'College' ELSE 'NonCollege' END AS edu_category,
   COUNT(DISTINCT cs_item_sk) AS distinct_item_count,
   SUM(DISTINCT cs_coupon_amt) AS distinct_coupon_sum,
   cs_net_paid_inc_tax
FROM catalog_sales
JOIN customer_demographics
   ON catalog_sales.cs_ship_cdemo_sk = customer_demographics.cd_demo_sk
WHERE cs_net_paid_inc_tax > (SELECT max_val FROM max_ship_tax)
  AND cd_dep_college_count = 1
GROUP BY cs_ship_customer_sk, cd_gender, cd_education_status, cs_net_paid_inc_tax

ORDER BY cs_net_paid_inc_tax DESC
LIMIT 100
