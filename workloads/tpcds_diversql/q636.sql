WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_quantity > 1
      AND cr_return_amount > 50
      AND cr_return_tax BETWEEN 0 AND 100
      AND cr_warehouse_sk = (SELECT max(cr_warehouse_sk) FROM catalog_returns)
      AND cr_refunded_hdemo_sk IN (5387, 2128, 6675)
),
key_set1 AS (
    SELECT cr_ship_mode_sk
    FROM sampled_returns
    WHERE cr_return_amount > 100
),
key_set2 AS (
    SELECT cr_ship_mode_sk
    FROM sampled_returns
    WHERE cr_return_tax > 20
),
intersect_keys AS (
    SELECT cr_ship_mode_sk
    FROM key_set1
    INTERSECT
    SELECT cr_ship_mode_sk
    FROM key_set2
),
joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_contract,
        CASE 
            WHEN cr.cr_return_amount > 200 THEN 'HIGH'
            WHEN cr.cr_return_amount > 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY cr.cr_return_amount DESC) AS rn_code,
        lr.total_return_amount
    FROM sampled_returns cr
    FULL OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    CROSS JOIN LATERAL (
        SELECT sum(cr2.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = cr.cr_ship_mode_sk
    ) lr
    WHERE cr.cr_ship_mode_sk IN (SELECT cr_ship_mode_sk FROM intersect_keys)
      AND sm.sm_contract LIKE 'A%'
      AND cr.cr_warehouse_sk = (SELECT max(cr_warehouse_sk) FROM catalog_returns)
)
SELECT *
FROM joined
WHERE rn_code <= 5
ORDER BY amount_category DESC, cr_return_amount DESC
LIMIT 100
