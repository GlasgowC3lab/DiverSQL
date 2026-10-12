WITH state_customer_agg AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS num_preferred,
        AVG(c.c_birth_year) AS avg_birth_year
    FROM
        customer c
    JOIN
        customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_birth_month IN (4, 7, 9)
        AND ca.ca_gmt_offset BETWEEN -5.00 AND 0.00
    GROUP BY
        ca.ca_state
    HAVING
        COUNT(DISTINCT c.c_customer_sk) >= 10
)
SELECT
    sca.ca_state,
    sca.num_customers,
    sca.num_preferred,
    sca.avg_birth_year,
    (SELECT AVG(inv_quantity_on_hand) FROM inventory) AS avg_inventory_qty,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper,
    ROW_NUMBER() OVER (ORDER BY sca.num_customers DESC) AS state_rank
FROM
    state_customer_agg sca
ORDER BY
    sca.num_customers DESC
LIMIT 10
