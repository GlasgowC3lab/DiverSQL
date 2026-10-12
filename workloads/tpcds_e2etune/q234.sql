WITH agg AS (
    SELECT
        c.c_birth_year AS birth_year,
        c.c_preferred_cust_flag AS preferred_cust_flag,
        COUNT(*) AS num_customers,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        AVG(hd.hd_dep_count) AS avg_dep_cnt,
        SUM(CASE WHEN hd.hd_buy_potential = 'High' THEN 1 ELSE 0 END) AS high_buy_potential_cnt
    FROM
        customer c
    JOIN
        household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        c.c_birth_year IN (1966, 1979, 1983)
        AND c.c_preferred_cust_flag IN ('Y', 'N')
        AND hd.hd_buy_potential IS NOT NULL
    GROUP BY
        c.c_birth_year,
        c.c_preferred_cust_flag
    HAVING
        COUNT(*) >= 10
)
SELECT
    birth_year,
    preferred_cust_flag,
    num_customers,
    avg_vehicle_cnt,
    avg_dep_cnt,
    high_buy_potential_cnt,
    RANK() OVER (PARTITION BY preferred_cust_flag ORDER BY avg_vehicle_cnt DESC) AS vehicle_cnt_rank
FROM
    agg
ORDER BY
    preferred_cust_flag,
    vehicle_cnt_rank
