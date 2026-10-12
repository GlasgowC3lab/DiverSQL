WITH ship_filtered AS (
    SELECT
        sm_ship_mode_sk,
        sm_ship_mode_id,
        sm_type,
        sm_code,
        sm_carrier,
        CONCAT(sm_carrier, '_', sm_code) AS carrier_code,
        CASE
            WHEN sm_type LIKE '%DAY%' THEN 'DAY_TYPE'
            ELSE 'OTHER_TYPE'
        END AS type_group
    FROM ship_mode
    WHERE regexp_like(sm_code, '^[A-Z]{4}$')
      AND sm_type LIKE '%DAY%'
),
return_filtered AS (
    SELECT
        cr_ship_mode_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_returned_date_sk,
        CASE
            WHEN cr_return_amount > 2000 THEN 'HIGH'
            WHEN cr_return_amount > 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS amount_category
    FROM catalog_returns
    WHERE cr_return_amount > 0
),
discount_set AS (
    SELECT multiplier
    FROM (VALUES (0.9), (1.0), (1.1)) AS t(multiplier)
),
agg AS (
    SELECT
        COALESCE(sf.sm_ship_mode_id, 'UNKNOWN') AS ship_mode_id,
        COALESCE(sf.type_group, 'NO_SHIP') AS type_group,
        rf.amount_category,
        d.multiplier,
        COUNT(*) AS cnt_returns,
        SUM(rf.cr_return_amount * d.multiplier) AS weighted_return_sum
    FROM return_filtered rf
    FULL OUTER JOIN ship_filtered sf
        ON rf.cr_ship_mode_sk = sf.sm_ship_mode_sk
    CROSS JOIN discount_set d
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = rf.cr_ship_mode_sk
          AND cr2.cr_return_amount > 1000
    )
    GROUP BY
        COALESCE(sf.sm_ship_mode_id, 'UNKNOWN'),
        COALESCE(sf.type_group, 'NO_SHIP'),
        rf.amount_category,
        d.multiplier
)
SELECT
    ship_mode_id,
    type_group,
    amount_category,
    multiplier,
    cnt_returns,
    weighted_return_sum,
    CASE
        WHEN weighted_return_sum > 5000 THEN 'VERY HIGH'
        WHEN weighted_return_sum > 2000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS sum_category
FROM agg
ORDER BY weighted_return_sum DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
