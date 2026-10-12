WITH
    agg_demo AS (
        SELECT
            d.cd_gender,
            d.cd_marital_status,
            COUNT(DISTINCT c.c_customer_sk) AS cust_cnt,
            SUM(d.cd_purchase_estimate) AS total_est,
            AVG(d.cd_purchase_estimate) AS avg_est,
            SUM(CASE WHEN d.cd_dep_count > 2 THEN 1 ELSE 0 END) AS high_dep_cnt
        FROM customer c
        FULL OUTER JOIN customer_demographics d
            ON c.c_current_cdemo_sk = d.cd_demo_sk
        WHERE c.c_birth_year BETWEEN 1970 AND 1990
            AND c.c_last_review_date >= 2452300
            AND d.cd_purchase_estimate > 4000
        GROUP BY d.cd_gender, d.cd_marital_status
    ),
    gender_a AS (
        SELECT d.cd_gender
        FROM customer c
        FULL OUTER JOIN customer_demographics d
            ON c.c_current_cdemo_sk = d.cd_demo_sk
        WHERE c.c_birth_month = 5
    ),
    gender_b AS (
        SELECT d.cd_gender
        FROM customer c
        FULL OUTER JOIN customer_demographics d
            ON c.c_current_cdemo_sk = d.cd_demo_sk
        WHERE c.c_birth_day = 1
    ),
    intersect_gender AS (
        SELECT cd_gender FROM gender_a
        INTERSECT
        SELECT cd_gender FROM gender_b
    )
SELECT
    d.cd_gender,
    AVG(d.avg_est) AS overall_avg_est,
    SUM(d.cust_cnt) AS total_customers,
    SUM(d.high_dep_cnt) AS total_high_dep
FROM agg_demo d
WHERE d.cd_gender IN (SELECT cd_gender FROM intersect_gender)
GROUP BY d.cd_gender
ORDER BY overall_avg_est DESC
LIMIT 100
