WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_year,
        c.c_birth_month,
        c.c_salutation,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_month IN (4, 12, 2)
      AND cd.cd_credit_rating IN ('A', 'B')
      AND c.c_salutation IN ('Mr.', 'Dr.', 'Ms.')
),
aggregated AS (
    SELECT
        cd_gender,
        cd_education_status,
        COUNT(DISTINCT c_customer_sk) AS cust_cnt,
        AVG(c_birth_year) AS avg_birth_year,
        SUM(cd_purchase_estimate) AS total_purchase_est,
        AVG(CASE WHEN c_salutation = 'Mr.' THEN 1 ELSE 0 END) AS pct_mr
    FROM filtered_customers
    GROUP BY cd_gender, cd_education_status
    HAVING COUNT(DISTINCT c_customer_sk) > 50
)
SELECT
    cd_gender,
    cd_education_status,
    cust_cnt,
    avg_birth_year,
    total_purchase_est,
    pct_mr,
    RANK() OVER (ORDER BY cust_cnt DESC) AS rank_by_cust_cnt
FROM aggregated
ORDER BY rank_by_cust_cnt
LIMIT 10
