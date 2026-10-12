SELECT
    ca.ca_state,
    hd.hd_income_band_sk,
    COUNT(*) AS total_customers,
    SUM(1) FILTER (WHERE c.c_preferred_cust_flag = 'Y') AS preferred_customers,
    AVG(c.c_birth_year) AS avg_birth_year,
    MIN(c.c_first_shipto_date_sk) AS min_first_ship_date_sk,
    MAX(c.c_last_review_date) AS max_last_review_date_sk,
    (SUM(1) FILTER (WHERE c.c_preferred_cust_flag = 'Y') * 1.0 / COUNT(*)) AS preferred_ratio,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS state_income_rank
FROM
    customer c
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    c.c_first_shipto_date_sk >= 2450000
    AND c.c_birth_year BETWEEN 1970 AND 2000
GROUP BY
    ca.ca_state,
    hd.hd_income_band_sk
HAVING
    COUNT(*) > 5
ORDER BY
    state_income_rank
LIMIT 20
