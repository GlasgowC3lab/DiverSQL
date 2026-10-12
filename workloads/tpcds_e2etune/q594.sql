WITH monthly_cp AS (
    SELECT COUNT(*) AS monthly_page_cnt
    FROM catalog_page cp
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_department = 'DEPARTMENT'
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_cnt,
    MAX(c.c_birth_year) AS max_birth_year,
    MIN(c.c_birth_year) AS min_birth_year,
    (SELECT monthly_page_cnt FROM monthly_cp) AS total_monthly_catalog_pages
FROM
    customer c
JOIN
    customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
    c.c_birth_year BETWEEN 1970 AND 2000
    AND cd.cd_credit_rating IN ('A', 'B', 'C')
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status
HAVING
    COUNT(*) > 5
ORDER BY
    avg_purchase_estimate DESC
LIMIT 100
