WITH agg_a AS (
    SELECT
        sm.sm_type,
        sm.sm_contract,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_call_center_sk IN (20, 14)
      AND sm.sm_type IN ('REGULAR', 'EXPRESS')
    GROUP BY GROUPING SETS (
        (sm.sm_type, sm.sm_contract),
        (sm.sm_type),
        ()
    )
),
agg_b AS (
    SELECT
        sm.sm_type,
        sm.sm_contract,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_call_center_sk IN (7, 22)
      AND sm.sm_type IN ('OVERNIGHT', 'TWO DAY')
    GROUP BY GROUPING SETS (
        (sm.sm_type, sm.sm_contract),
        (sm.sm_type),
        ()
    )
),
intersect_keys AS (
    SELECT sm_type, sm_contract FROM agg_a
    INTERSECT
    SELECT sm_type, sm_contract FROM agg_b
),
final AS (
    SELECT
        i.sm_type,
        i.sm_contract,
        a.total_return_amount,
        a.cnt,
        SUM(a.total_return_amount) OVER (
            PARTITION BY i.sm_type
            ORDER BY i.sm_contract
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_return,
        LAG(a.cnt) OVER (
            PARTITION BY i.sm_type
            ORDER BY i.sm_contract
        ) AS prior_cnt
    FROM intersect_keys i
    LEFT JOIN agg_a a
        ON a.sm_type = i.sm_type AND a.sm_contract = i.sm_contract
    LEFT JOIN agg_b b
        ON b.sm_type = i.sm_type AND b.sm_contract = i.sm_contract
)
SELECT
    sm_type,
    sm_contract,
    total_return_amount,
    cnt,
    running_total_return,
    prior_cnt
FROM final
ORDER BY sm_type, sm_contract
LIMIT 100
