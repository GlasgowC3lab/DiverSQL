WITH gender_marital_stats AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(c.c_birth_year) AS avg_birth_year,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_count
    FROM
        customer c
    JOIN
        customer_demographics cd
            ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_month IN (4, 7, 9)
        AND c.c_birth_country IN ('CHILE', 'MEXICO')
        AND c.c_salutation = 'Mr.'
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
    HAVING
        COUNT(DISTINCT c.c_customer_sk) > 5
)
SELECT
    cd_gender,
    cd_marital_status,
    num_customers,
    avg_birth_year,
    preferred_count,
    (preferred_count * 100.0) / num_customers AS preferred_pct,
    RANK() OVER (ORDER BY num_customers DESC) AS rank_by_customers
FROM
    gender_marital_stats
ORDER BY
    num_customers DESC
LIMIT 50
