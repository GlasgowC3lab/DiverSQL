SELECT cd.cd_gender,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       t.t_meal_time,
       COUNT(*) AS num_customers,
       AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
       SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
       RANK() OVER (ORDER BY AVG(cd.cd_purchase_estimate) DESC) AS purchase_rank
FROM customer_demographics cd
JOIN income_band ib
  ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
JOIN time_dim t
  ON t.t_hour = cd.cd_dep_count
WHERE cd.cd_gender = 'F'
  AND cd.cd_marital_status = 'M'
  AND cd.cd_education_status = 'College'
GROUP BY cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound, t.t_meal_time
ORDER BY purchase_rank
LIMIT 20
