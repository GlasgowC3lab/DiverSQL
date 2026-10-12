WITH open_2022 AS (
    SELECT
        cc.cc_state AS state,
        'OPEN_2022' AS status,
        COUNT(*) AS cnt
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim dd ON cc.cc_open_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY cc.cc_state
),
closed_2023 AS (
    SELECT
        cc.cc_state AS state,
        'CLOSED_2023' AS status,
        COUNT(*) AS cnt
    FROM tpcds.call_center cc
    WHERE EXISTS (
        SELECT 1
        FROM tpcds.date_dim dd
        WHERE dd.d_date_sk = cc.cc_closed_date_sk
          AND dd.d_year = 2023
    )
    GROUP BY cc.cc_state
)
SELECT state, status, cnt
FROM open_2022
UNION
SELECT state, status, cnt
FROM closed_2023
ORDER BY state, status
