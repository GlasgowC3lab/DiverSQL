WITH grouped AS (
    SELECT
        ib.ib_income_band_sk,
        cd.cd_education_status,
        cd.cd_gender,
        COUNT(*) AS customer_cnt,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_dep_count) AS avg_dependents,
        SUM(cd.cd_dep_college_count) AS total_college_dependents
    FROM
        customer_demographics cd
    JOIN
        income_band ib
        ON cd.cd_purchase_estimate >= ib.ib_lower_bound
           AND cd.cd_purchase_estimate < ib.ib_upper_bound
    WHERE
        cd.cd_dep_college_count >= 1
        AND cd.cd_marital_status IN ('M', 'S')
    GROUP BY
        ib.ib_income_band_sk,
        cd.cd_education_status,
        cd.cd_gender
    HAVING
        COUNT(*) > 5
)
SELECT
    ib_income_band_sk,
    cd_education_status,
    cd_gender,
    customer_cnt,
    total_purchase_estimate,
    avg_dependents,
    total_college_dependents,
    RANK() OVER (PARTITION BY cd_education_status ORDER BY total_purchase_estimate DESC) AS rank_by_education
FROM
    grouped
ORDER BY
    cd_education_status,
    rank_by_education,
    total_purchase_estimate DESC
