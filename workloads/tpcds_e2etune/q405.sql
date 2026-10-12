SELECT
    cd_education_status,
    t_shift,
    demo_count,
    total_estimate,
    avg_college_deps,
    RANK() OVER (ORDER BY total_estimate DESC) AS rnk
FROM (
    SELECT
        cd.cd_education_status,
        td.t_shift,
        COUNT(*) AS demo_count,
        SUM(cd.cd_purchase_estimate) AS total_estimate,
        AVG(cd.cd_dep_college_count) AS avg_college_deps
    FROM customer_demographics cd
    CROSS JOIN time_dim td
    WHERE cd.cd_credit_rating = 'Good'
      AND td.t_meal_time = 'Lunch'
      AND cd.cd_purchase_estimate >= 1000
    GROUP BY cd.cd_education_status, td.t_shift
    HAVING COUNT(*) > 5
) sub
ORDER BY total_estimate DESC
LIMIT 20
