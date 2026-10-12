WITH address_demo AS (
    SELECT
        ca.ca_state,
        ca.ca_address_sk,
        ca.ca_gmt_offset,
        hd.hd_vehicle_count,
        hd.hd_buy_potential
    FROM
        customer_address ca
        JOIN household_demographics hd
            ON ca.ca_address_sk = hd.hd_demo_sk
    WHERE
        ca.ca_country = 'United States'
),
joined_time AS (
    SELECT
        ad.ca_state,
        t.t_shift,
        ad.hd_vehicle_count,
        ad.hd_buy_potential
    FROM
        address_demo ad
        JOIN time_dim t
            ON ((CAST(FLOOR(ad.ca_gmt_offset) AS integer) + 24) % 24) = t.t_hour
    WHERE
        t.t_shift IS NOT NULL
),
aggregated AS (
    SELECT
        ca_state,
        t_shift,
        COUNT(*) AS address_count,
        AVG(hd_vehicle_count) AS avg_vehicles,
        SUM(CASE WHEN hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_potential_cnt
    FROM
        joined_time
    GROUP BY
        ca_state,
        t_shift
    HAVING
        COUNT(*) > 10
)
SELECT
    ca_state,
    t_shift,
    address_count,
    avg_vehicles,
    high_potential_cnt,
    RANK() OVER (PARTITION BY ca_state ORDER BY avg_vehicles DESC) AS vehicle_rank
FROM
    aggregated
ORDER BY
    avg_vehicles DESC
LIMIT 100
