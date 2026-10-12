WITH gender_marital_stats AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(*) AS cust_cnt,
        AVG(cd_purchase_estimate) AS avg_purchase_est,
        SUM(cd_dep_employed_count) AS total_employed_deps,
        SUM(cd_dep_college_count) AS total_college_deps
    FROM customer_demographics
    WHERE cd_purchase_estimate >= 1000
      AND cd_dep_count > 0
    GROUP BY cd_gender, cd_marital_status
)
SELECT
    cd_gender,
    cd_marital_status,
    cust_cnt,
    avg_purchase_est,
    total_employed_deps,
    total_college_deps,
    cust_cnt * 100.0 / SUM(cust_cnt) OVER () AS pct_of_total_customers,
    RANK() OVER (PARTITION BY cd_gender ORDER BY avg_purchase_est DESC) AS rank_within_gender,
    RANK() OVER (ORDER BY avg_purchase_est DESC) AS overall_rank
FROM gender_marital_stats
ORDER BY overall_rank
