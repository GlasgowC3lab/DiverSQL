WITH address_words AS (
    SELECT
        c.c_customer_id,
        ca.ca_country,
        ca.ca_state,
        ca.ca_street_type,
        ca.ca_location_type,
        word AS street_word
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    CROSS JOIN UNNEST(split(ca.ca_street_name, ' ')) AS t(word)
    WHERE ca.ca_country = 'United States'
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_current_hdemo_sk IN (5913, 7006)
),
grouped AS (
    SELECT
        ca_country,
        ca_state,
        ca_street_type,
        COUNT(DISTINCT c_customer_id) AS customer_cnt,
        COUNT(DISTINCT street_word) AS distinct_street_word_cnt
    FROM address_words
    GROUP BY ca_country, ca_state, ca_street_type
)
SELECT
    ca_country,
    ca_state,
    ca_street_type,
    SUM(customer_cnt) AS total_customers,
    SUM(distinct_street_word_cnt) AS total_distinct_street_words,
    (SELECT COUNT(*) FROM customer) AS overall_customer_count
FROM grouped
GROUP BY ROLLUP (ca_country, ca_state, ca_street_type)
HAVING SUM(customer_cnt) > (SELECT AVG(customer_cnt) FROM grouped)
ORDER BY ca_country, ca_state, ca_street_type
LIMIT 100
