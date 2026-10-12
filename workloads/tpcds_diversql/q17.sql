WITH returns_by_division AS (
    SELECT
        cc.cc_state AS region,
        'ReturnAmount' AS metric_type,
        CAST(SUM(cr.cr_return_amount) AS decimal(18,2)) AS metric_value
    FROM catalog_returns cr
    FULL OUTER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY cc.cc_state
    HAVING SUM(cr.cr_return_amount) IS NOT NULL
),
closed_stores AS (
    SELECT
        s.s_state AS region,
        'ClosedStores' AS metric_type,
        CAST(COUNT(*) AS decimal(18,2)) AS metric_value
    FROM store s
    FULL OUTER JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_state
)
SELECT region, metric_type, metric_value
FROM returns_by_division
UNION ALL
SELECT region, metric_type, metric_value
FROM closed_stores
ORDER BY region ASC, metric_type
LIMIT 100
