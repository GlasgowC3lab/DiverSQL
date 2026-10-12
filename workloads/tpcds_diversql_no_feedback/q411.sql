WITH refunded AS (
    SELECT
        CAST(hd.hd_income_band_sk AS VARCHAR) AS grp_key,
        sm.sm_code AS ship_attr,
        SUM(cr.cr_return_amount) AS metric,
        CASE WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS metric_category,
        'REFUNDED' AS source
    FROM catalog_returns AS cr
    INNER JOIN household_demographics AS hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN ship_mode AS sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE hd.hd_income_band_sk BETWEEN 10 AND 15
    GROUP BY hd.hd_income_band_sk, sm.sm_code
),
returning AS (
    SELECT
        hd.hd_buy_potential AS grp_key,
        sm.sm_type AS ship_attr,
        AVG(cr.cr_fee) AS metric,
        CASE WHEN AVG(cr.cr_fee) > 50 THEN 'EXPENSIVE' ELSE 'CHEAP' END AS metric_category,
        'RETURNING' AS source
    FROM catalog_returns AS cr
    INNER JOIN household_demographics AS hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    INNER JOIN ship_mode AS sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE hd.hd_dep_count >= 2
    GROUP BY hd.hd_buy_potential, sm.sm_type
),
combined AS (
    SELECT * FROM refunded
    UNION ALL
    SELECT * FROM returning
),
small_dim AS (
    SELECT CAST('North' AS VARCHAR) AS region
    UNION ALL SELECT 'South'
    UNION ALL SELECT 'East'
    UNION ALL SELECT 'West'
)
SELECT
    c.grp_key,
    c.ship_attr,
    c.metric,
    c.metric_category,
    c.source,
    d.region
FROM combined AS c
CROSS JOIN small_dim AS d
ORDER BY c.metric DESC, d.region
LIMIT 100
