WITH cust AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        CASE
            WHEN hd.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low'
            WHEN hd.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Medium'
            ELSE 'High'
        END AS income_band_category,
        (year(current_date) - c.c_birth_year) AS age,
        RANK() OVER (ORDER BY hd.hd_vehicle_count DESC, (year(current_date) - c.c_birth_year)) AS vehicle_rank,
        SUM(hd.hd_vehicle_count) OVER (PARTITION BY ca.ca_city) AS city_total_vehicles
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_city,
    hd_vehicle_count,
    hd_dep_count,
    income_band_category,
    age,
    vehicle_rank,
    city_total_vehicles
FROM cust
WHERE vehicle_rank <= 10
ORDER BY vehicle_rank
