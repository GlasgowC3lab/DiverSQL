WITH filtered_customers AS (
    SELECT
        ca.ca_state AS state,
        ca.ca_city AS city,
        c.c_customer_sk AS cust_sk,
        c.c_birth_year AS birth_year,
        c.c_last_review_date AS last_review_date
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1960 AND 2000
)
SELECT
    state,
    city,
    COUNT(DISTINCT cust_sk) AS customer_cnt,
    AVG(birth_year) AS avg_birth_year,
    MIN(last_review_date) AS earliest_review_date,
    (SELECT AVG(cc_tax_percentage) FROM call_center WHERE cc_country = 'United States') AS us_avg_tax_pct,
    (SELECT COUNT(*) FROM call_center WHERE cc_country = 'United States' AND cc_employees > 3000000) AS large_employee_cc_cnt
FROM filtered_customers
GROUP BY state, city
HAVING COUNT(*) >= 50
ORDER BY customer_cnt DESC
LIMIT 100
