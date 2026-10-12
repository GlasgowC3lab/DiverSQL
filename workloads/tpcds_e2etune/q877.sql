WITH base AS (
    SELECT
        ca_state,
        ca_county,
        COUNT(*) AS customer_cnt,
        AVG(year(current_date) - c_birth_year) AS avg_age,
        SUM(CASE WHEN c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pref_cust_ratio
    FROM
        customer c
    JOIN
        customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_birth_country = 'MEXICO'
        AND c.c_birth_year >= 1985
        AND c.c_preferred_cust_flag IS NOT NULL
    GROUP BY
        ca_state,
        ca_county
    HAVING
        COUNT(*) >= 5
)
SELECT
    ca_state,
    ca_county,
    customer_cnt,
    avg_age,
    pref_cust_ratio,
    RANK() OVER (ORDER BY customer_cnt DESC) AS cnt_rank
FROM
    base
ORDER BY
    customer_cnt DESC
LIMIT 10
