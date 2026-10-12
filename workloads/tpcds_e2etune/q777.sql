WITH agg AS (
    SELECT
        cc.cc_state,
        cd.cd_gender,
        t.t_hour,
        COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
        SUM(cc.cc_employees) AS total_employees,
        AVG(cc.cc_tax_percentage) AS avg_tax_pct,
        COUNT(DISTINCT hd.hd_demo_sk) FILTER (WHERE hd.hd_buy_potential = 'HIGH') AS high_buy_potential_households,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM call_center cc
    JOIN time_dim t
        ON cc.cc_open_date_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON cc.cc_open_date_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE cc.cc_state IN ('TN', 'LA', 'GA')
      AND cc.cc_tax_percentage > 0.00
      AND cd.cd_gender = 'F'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        cc.cc_state,
        cd.cd_gender,
        t.t_hour
)
SELECT
    cc_state,
    cd_gender,
    t_hour,
    num_call_centers,
    total_employees,
    avg_tax_pct,
    high_buy_potential_households,
    avg_vehicle_count,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_employees DESC) AS employee_rank_by_state
FROM agg
ORDER BY total_employees DESC, cc_state
