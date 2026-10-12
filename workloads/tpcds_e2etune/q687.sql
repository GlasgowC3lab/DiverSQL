WITH shipments AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        sm.sm_ship_mode_sk,
        sm.sm_type,
        ((d.d_date_sk + sm.sm_ship_mode_sk) % 1000) + 1 AS weight,
        ((d.d_date_sk * sm.sm_ship_mode_sk) % 10) + 1 AS delay_days
    FROM date_dim d
    CROSS JOIN ship_mode sm
    WHERE d.d_current_year = 'Y'
      AND sm.sm_carrier IN ('UPS', 'FedEx')
),
agg AS (
    SELECT
        d_year,
        sm_type,
        SUM(weight) AS total_weight,
        AVG(delay_days) AS avg_delay,
        COUNT(*) AS shipment_count
    FROM shipments
    GROUP BY d_year, sm_type
    HAVING SUM(weight) > 5000
)
SELECT
    d_year,
    sm_type,
    total_weight,
    avg_delay,
    shipment_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_weight DESC) AS rank_by_weight
FROM agg
ORDER BY d_year, rank_by_weight
LIMIT 100
