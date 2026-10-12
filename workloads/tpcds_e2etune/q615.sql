WITH state_metrics AS (
    SELECT
        ca.ca_state AS state,
        COUNT(DISTINCT ca.ca_address_sk) AS num_customers,
        AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
        SUM(s.s_floor_space) AS total_store_floor_space,
        SUM(w.w_warehouse_sq_ft) AS total_warehouse_sq_ft
    FROM
        customer_address ca
        JOIN store s
            ON ca.ca_state = s.s_state
            AND ca.ca_city = s.s_city
        JOIN warehouse w
            ON s.s_state = w.w_state
            AND s.s_city = w.w_city
    WHERE
        ca.ca_gmt_offset < -5.00
        AND s.s_closed_date_sk IS NULL
    GROUP BY
        ca.ca_state
    HAVING
        COUNT(DISTINCT ca.ca_address_sk) >= 5
)
SELECT
    state,
    num_customers,
    avg_gmt_offset,
    total_store_floor_space,
    total_warehouse_sq_ft,
    RANK() OVER (ORDER BY (total_store_floor_space + total_warehouse_sq_ft) DESC) AS state_rank
FROM
    state_metrics
ORDER BY
    state_rank
LIMIT 20
