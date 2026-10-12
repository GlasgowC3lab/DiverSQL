WITH cust_demo AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_country IN ('IRELAND', 'CYPRUS', 'VANUATU')
      AND c.c_birth_year BETWEEN 1970 AND 1995
),

agg AS (
    SELECT
        c.c_birth_country,
        c.cd_gender,
        COUNT(*) AS customer_cnt,
        SUM(c.cd_purchase_estimate) AS total_purchase_est,
        AVG(c.cd_purchase_estimate) AS avg_purchase_est,
        AVG(c.cd_dep_count) AS avg_dependents
    FROM cust_demo c
    GROUP BY c.c_birth_country, c.cd_gender
    HAVING COUNT(*) >= 5
)

SELECT
    a.c_birth_country,
    a.cd_gender,
    a.customer_cnt,
    a.total_purchase_est,
    a.avg_purchase_est,
    a.avg_dependents,
    RANK() OVER (PARTITION BY a.cd_gender ORDER BY a.total_purchase_est DESC) AS gender_country_rank
FROM agg a
ORDER BY a.total_purchase_est DESC
LIMIT 10
