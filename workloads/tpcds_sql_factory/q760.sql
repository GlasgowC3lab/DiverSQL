SELECT
    w.w_warehouse_sk,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    w.w_state AS warehouse_state,
    ca_ship.ca_city AS ship_city,
    hd_ship.hd_vehicle_count,
    CASE
        WHEN hd_ship.hd_vehicle_count <= 1 THEN 'LOW_VEHICLE'
        WHEN hd_ship.hd_vehicle_count BETWEEN 2 AND 3 THEN 'MEDIUM_VEHICLE'
        ELSE 'HIGH_VEHICLE'
    END AS vehicle_category,
    cs.cs_ship_date_sk,
    cs.cs_net_paid,
    SUM(cs.cs_net_paid) OVER (
        PARTITION BY w.w_warehouse_sk
        ORDER BY cs.cs_ship_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_paid,
    ROW_NUMBER() OVER (
        PARTITION BY w.w_warehouse_sk, hd_ship.hd_vehicle_count
        ORDER BY cs.cs_ship_date_sk DESC
    ) AS recent_ship_rank,
    DENSE_RANK() OVER (
        PARTITION BY w.w_warehouse_sk
        ORDER BY cs.cs_net_paid DESC
    ) AS net_paid_rank
FROM catalog_sales cs
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE cs.cs_ship_date_sk IS NOT NULL
ORDER BY w.w_warehouse_sk, cs.cs_ship_date_sk
