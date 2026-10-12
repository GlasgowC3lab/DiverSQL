WITH cust_agg AS (
    SELECT
        c_current_cdemo_sk,
        COUNT(*) AS cust_cnt,
        MIN(c_first_shipto_date_sk) AS min_ship_date,
        MAX(c_last_review_date) AS max_review_date
    FROM tpcds.customer
    WHERE c_birth_year BETWEEN 1960 AND 1990
      AND c_preferred_cust_flag = 'Y'
      AND c_first_sales_date_sk > 2451000
    GROUP BY c_current_cdemo_sk
),
joined AS (
    SELECT
        ca.c_current_cdemo_sk,
        ca.cust_cnt,
        ca.min_ship_date,
        ca.max_review_date,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count
    FROM cust_agg ca
    FULL OUTER JOIN tpcds.customer_demographics d
        ON ca.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(j.cust_cnt, 0) DESC, j.cd_gender) AS rn,
    j.c_current_cdemo_sk,
    j.cust_cnt,
    j.cd_gender,
    j.cd_marital_status,
    SUM(j.cust_cnt) OVER (PARTITION BY j.cd_gender) AS total_cust_by_gender,
    AVG(j.cd_purchase_estimate) OVER (PARTITION BY j.cd_gender) AS avg_purchase_estimate_gender,
    j.cd_purchase_estimate,
    j.cd_dep_count,
    j.cd_dep_employed_count,
    j.cd_dep_college_count
FROM joined j
WHERE j.cd_dep_count IS NOT NULL AND j.cd_dep_count >= 2
  AND j.cd_purchase_estimate IS NOT NULL AND j.cd_purchase_estimate > 1000
  AND j.cust_cnt IS NOT NULL AND j.cust_cnt <= 500
ORDER BY rn
OFFSET 0
LIMIT 100
