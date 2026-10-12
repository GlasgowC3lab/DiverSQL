WITH cust_stats AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        COUNT(*) AS cust_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cust_cnt
    FROM
        customer c
    JOIN
        customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
        AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY
        ca.ca_state,
        ca.ca_city
    HAVING
        COUNT(*) >= 10
)
SELECT
    cs.ca_state,
    cs.ca_city,
    cs.cust_cnt,
    cs.avg_birth_year,
    cs.pref_cust_cnt,
    (SELECT SUM(p.p_cost) FROM promotion p WHERE p.p_discount_active = 'Y') AS total_active_promo_cost,
    RANK() OVER (ORDER BY cs.cust_cnt DESC) AS city_rank
FROM
    cust_stats cs
ORDER BY
    cs.cust_cnt DESC
LIMIT 100
