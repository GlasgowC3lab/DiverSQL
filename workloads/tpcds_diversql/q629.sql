WITH sampled_returns AS (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)    -- sample 10% of rows
    ),
    agg_returns AS (
        SELECT
            cr_ship_mode_sk,
            SUM(cr_return_amount)          AS total_return_amount,
            SUM(cr_return_quantity)        AS total_quantity,
            COUNT(*)                       AS return_cnt,
            AVG(cr_return_tax)             AS avg_tax
        FROM sampled_returns
        WHERE cr_return_quantity > 5                     -- predicate 1
          AND cr_return_amount   > 100                    -- predicate 2
        GROUP BY cr_ship_mode_sk
    ),
    lateral_ship AS (
        SELECT
            sm.sm_ship_mode_sk                               AS ship_mode_sk,
            sm.sm_type                                      AS ship_type,
            sm.sm_code                                      AS ship_code,
            sm.sm_carrier,
            cr.total_return_amount,
            cr.total_quantity,
            cr.return_cnt,
            cr.avg_tax,
            lt.late_cnt
        FROM ship_mode sm
        FULL OUTER JOIN agg_returns cr
            ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk      -- join rule
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS late_cnt
            FROM catalog_returns cr2
            WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
              AND cr2.cr_return_amount > 50                 -- predicate 3 inside lateral
        ) lt ON TRUE
        WHERE sm.sm_type = 'OVERNIGHT'                     -- predicate 4
          AND sm.sm_code IN ('AIR', 'BIKE')                -- predicate 5
    )
SELECT
    ship_mode_sk,
    ship_type,
    ship_code,
    sm_carrier,
    COALESCE(total_return_amount, 0) AS total_return_amount,
    COALESCE(total_quantity, 0)       AS total_quantity,
    COALESCE(return_cnt, 0)           AS return_cnt,
    avg_tax,
    late_cnt,
    CASE
        WHEN total_return_amount > (
                SELECT AVG(cr_return_amount)
                FROM catalog_returns
                WHERE cr_return_quantity > 10          -- scalar sub‑query, uncorrelated
            ) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS amount_category
FROM lateral_ship
WHERE (return_cnt IS NOT NULL AND return_cnt > 10)
   OR total_return_amount IS NULL                     -- keep ship modes with no returns
ORDER BY total_return_amount DESC NULLS LAST
LIMIT 100
