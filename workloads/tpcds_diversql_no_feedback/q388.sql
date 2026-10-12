WITH ship_no_returns AS (
    SELECT sm_ship_mode_sk
    FROM ship_mode
    EXCEPT
    SELECT DISTINCT cr_ship_mode_sk
    FROM catalog_returns
),
ship_agg AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_code,
        sm.sm_contract,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        COUNT(cr.cr_return_amount) AS return_count
    FROM catalog_returns cr
    RIGHT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(sm.sm_contract, '^U')
      AND sm.sm_carrier LIKE '%A%'
    GROUP BY sm.sm_ship_mode_sk, sm.sm_carrier, sm.sm_code, sm.sm_contract
)
SELECT
    CONCAT(agg.sm_carrier, '-', agg.sm_code) AS carrier_code,
    agg.total_return_amount,
    agg.return_count
FROM ship_agg agg
JOIN ship_no_returns sr
    ON agg.sm_ship_mode_sk = sr.sm_ship_mode_sk
ORDER BY agg.total_return_amount DESC
LIMIT 100
