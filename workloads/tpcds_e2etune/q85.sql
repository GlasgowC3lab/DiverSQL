SELECT
    cd.cd_education_status,
    r.r_reason_desc,
    COUNT(*) AS num_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(cd.cd_dep_employed_count) AS total_employed_deps,
    RANK() OVER (ORDER BY AVG(cd.cd_purchase_estimate) DESC) AS purchase_rank
FROM customer_demographics cd
JOIN reason r ON TRUE
WHERE cd.cd_marital_status IN ('M', 'S')
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_employed_count >= 1
GROUP BY cd.cd_education_status, r.r_reason_desc
HAVING COUNT(*) >= 5
ORDER BY avg_purchase_estimate DESC
LIMIT 100
