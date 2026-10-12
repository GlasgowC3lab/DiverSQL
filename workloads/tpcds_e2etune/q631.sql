WITH store_stats AS (
    SELECT s_store_sk, s_state, s_country, s_tax_percentage
    FROM store
    WHERE s_country = 'United States'
),
customer_filtered AS (
    SELECT c_customer_sk, c_birth_year, c_birth_month, c_email_address,
           CASE WHEN regexp_like(c_email_address, '@[^.]+\\.com$') THEN 'com' ELSE 'other' END AS email_domain_type
    FROM customer
    WHERE c_birth_month IN (5, 6, 12)
)
SELECT ss.s_state,
       COUNT(DISTINCT cf.c_customer_sk) AS num_customers,
       AVG(cf.c_birth_year) AS avg_birth_year,
       SUM(ss.s_tax_percentage) AS total_tax_percentage,
       COUNT(DISTINCT CASE WHEN cf.email_domain_type = 'com' THEN cf.c_customer_sk END) AS com_email_customers,
       RANK() OVER (ORDER BY COUNT(DISTINCT cf.c_customer_sk) DESC) AS state_rank
FROM store_stats ss
JOIN customer_filtered cf ON 1 = 1
GROUP BY ss.s_state
HAVING COUNT(DISTINCT cf.c_customer_sk) >= 100
ORDER BY num_customers DESC
LIMIT 15
