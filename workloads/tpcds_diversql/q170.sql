WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_order_number,
        r.r_reason_sk,
        r.r_reason_desc,
        r.r_reason_id
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_reversed_charge > 100.00
      AND cr.cr_store_credit > 500.00
      AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
),
aggregated AS (
    SELECT
        r_reason_sk AS key,
        r_reason_desc AS description,
        SUM(cr_return_amount) AS metric,
        ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amount) DESC) AS rn
    FROM filtered_returns
    GROUP BY r_reason_sk, r_reason_desc
),
intersect_orders AS (
    SELECT cr_order_number AS key
    FROM catalog_returns
    WHERE cr_reversed_charge > 200.00
    INTERSECT
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_store_credit > 800.00
),
intersect_select AS (
    SELECT
        key,
        CAST(NULL AS varchar) AS description,
        CAST(NULL AS decimal(7,2)) AS metric,
        CAST(NULL AS bigint) AS rn
    FROM intersect_orders
)
SELECT key, description, metric, rn
FROM aggregated
UNION
SELECT key, description, metric, rn
FROM intersect_select
LIMIT 100
