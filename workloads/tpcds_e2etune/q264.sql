SELECT cp.cp_department,
       COUNT(DISTINCT c.c_customer_sk) AS num_customers,
       SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers,
       AVG(ib.ib_upper_bound - ib.ib_lower_bound) AS avg_income_band_range,
       MIN(cp.cp_start_date_sk) AS earliest_catalog_start,
       MAX(cp.cp_end_date_sk) AS latest_catalog_end
FROM catalog_page cp
JOIN customer c
  ON cp.cp_catalog_number = c.c_birth_month
JOIN income_band ib
  ON c.c_current_cdemo_sk = ib.ib_income_band_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_department IN ('DEPARTMENT', 'SALES')
  AND c.c_preferred_cust_flag IS NOT NULL
GROUP BY cp.cp_department
HAVING COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY num_customers DESC
LIMIT 50
