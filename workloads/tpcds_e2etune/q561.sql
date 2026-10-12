WITH cust_demo AS (
   SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      COUNT(*) AS cust_cnt,
      AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
      SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cust_cnt
   FROM customer c
   JOIN customer_demographics cd
     ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE c.c_preferred_cust_flag = 'Y'
     AND c.c_birth_year BETWEEN 1970 AND 1990
     AND c.c_current_cdemo_sk IN (980124, 819667, 1473522)
   GROUP BY cd.cd_gender, cd.cd_marital_status
   HAVING COUNT(*) > 5
)
SELECT
   cd_gender,
   cd_marital_status,
   cust_cnt,
   avg_purchase_estimate,
   pref_cust_cnt,
   (SELECT AVG(p_cost) FROM promotion WHERE p_start_date_sk >= 2450000) AS avg_recent_promo_cost,
   (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y' AND p_cost > 100) AS high_discount_promo_cnt,
   (SELECT r_reason_desc FROM reason WHERE r_reason_id = 'R001' LIMIT 1) AS sample_reason_desc,
   RANK() OVER (ORDER BY avg_purchase_estimate DESC) AS purchase_est_rank
FROM cust_demo
ORDER BY purchase_est_rank
LIMIT 10
