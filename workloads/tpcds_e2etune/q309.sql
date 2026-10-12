WITH address_agg AS (
    SELECT
        ca_state,
        AVG(ca_gmt_offset) AS avg_gmt_offset,
        COUNT(*) AS addr_cnt,
        COUNT(DISTINCT ca_zip) AS distinct_zip_cnt
    FROM customer_address
    WHERE ca_country = 'United States'
      AND ca_gmt_offset IS NOT NULL
      AND ca_state IS NOT NULL
      AND ca_zip LIKE '8%'
    GROUP BY ca_state
),
ship_agg AS (
    SELECT
        sm_carrier,
        COUNT(*) AS ship_mode_cnt,
        COUNT(DISTINCT sm_type) AS distinct_type_cnt
    FROM ship_mode
    WHERE sm_type IN ('AIR', 'GROUND')
    GROUP BY sm_carrier
)
SELECT
    a.ca_state,
    s.sm_carrier,
    a.avg_gmt_offset,
    a.addr_cnt,
    s.ship_mode_cnt,
    RANK() OVER (PARTITION BY a.ca_state ORDER BY s.ship_mode_cnt DESC) AS carrier_rank_by_ship_modes
FROM address_agg a
JOIN ship_agg s
  ON substr(a.ca_state, 1, 1) = substr(s.sm_carrier, 1, 1)
WHERE a.addr_cnt > 10
ORDER BY a.addr_cnt DESC, s.ship_mode_cnt DESC
LIMIT 100
