WITH catalog_active AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_type,
        d_start.d_date AS start_date,
        d_end.d_date AS end_date,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
    WHERE cp.cp_type = 'monthly'
      AND d_end.d_year = 2022
      AND cp.cp_start_date_sk BETWEEN 2450815 AND 2451088
),
customers_in_period AS (
    SELECT
        c.c_customer_id,
        c.c_birth_year,
        c.c_current_hdemo_sk,
        c.c_first_sales_date_sk,
        d_sales.d_year,
        d_sales.d_date
    FROM customer c
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 2000
)
SELECT
    ca.cp_department,
    ca.cp_catalog_number,
    COUNT(DISTINCT cip.c_customer_id) AS distinct_customers,
    AVG(cip.d_year - cip.c_birth_year) AS avg_customer_age_at_first_sale,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT cip.c_customer_id) DESC) AS dept_rank
FROM catalog_active ca
JOIN customers_in_period cip
    ON cip.c_first_sales_date_sk BETWEEN ca.cp_start_date_sk AND ca.cp_end_date_sk
JOIN household_demographics hd
    ON cip.c_current_hdemo_sk = hd.hd_demo_sk
GROUP BY ca.cp_department, ca.cp_catalog_number
ORDER BY distinct_customers DESC
LIMIT 100
