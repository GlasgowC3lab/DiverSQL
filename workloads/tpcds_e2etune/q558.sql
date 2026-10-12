WITH agg AS (
    SELECT
        ca.ca_state,
        sm.sm_type,
        COUNT(DISTINCT ca.ca_address_id) AS num_addresses,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_dep_count) AS avg_dep_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        COUNT(*) FILTER (WHERE cd.cd_credit_rating = 'A') AS num_credit_A
    FROM
        customer_address ca
    JOIN
        customer_demographics cd
        ON ca.ca_address_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd
        ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN
        ship_mode sm
        ON (ca.ca_address_sk % 10) = (sm.sm_ship_mode_sk % 10)
    WHERE
        ca.ca_state IN ('AZ', 'NM', 'PA')
        AND ca.ca_location_type = 'single family'
        AND cd.cd_credit_rating IN ('A', 'B')
        AND hd.hd_buy_potential = 'High'
    GROUP BY
        ca.ca_state,
        sm.sm_type
    HAVING
        SUM(cd.cd_purchase_estimate) > 1000
)
SELECT
    ca_state,
    sm_type,
    num_addresses,
    total_purchase_estimate,
    avg_dep_count,
    avg_vehicle_count,
    num_credit_A,
    RANK() OVER (ORDER BY total_purchase_estimate DESC) AS purchase_rank
FROM agg
ORDER BY purchase_rank
LIMIT 50
