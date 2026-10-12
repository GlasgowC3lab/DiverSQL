SELECT
    department,
    unique_customers,
    avg_page_number,
    total_active_days,
    RANK() OVER (ORDER BY total_active_days DESC) AS dept_rank
FROM (
    SELECT
        cp.cp_department AS department,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cp.cp_catalog_page_number) AS avg_page_number,
        SUM(cp.cp_end_date_sk - cp.cp_start_date_sk) AS total_active_days
    FROM catalog_page cp
    JOIN customer c
        ON TRUE
    WHERE cp.cp_catalog_number IN (1, 2, 3)
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY cp.cp_department
    HAVING COUNT(DISTINCT c.c_customer_sk) > 5
) AS dept_stats
ORDER BY total_active_days DESC
LIMIT 10
