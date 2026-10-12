WITH recent_returns AS (
        SELECT cr.cr_order_number,
               d.d_year
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    old_returns AS (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
    ),
    unique_recent AS (
        SELECT cr_order_number
        FROM recent_returns
        EXCEPT
        SELECT cr_order_number
        FROM old_returns
    ),
    unique_recent_rows AS (
        SELECT CAST(ur.cr_order_number AS varchar) AS id,
               'UniqueRecent' AS source,
               rr.d_year AS year
        FROM unique_recent ur
        JOIN recent_returns rr ON ur.cr_order_number = rr.cr_order_number
    ),
    full_join_rows AS (
        SELECT COALESCE(cc.cc_call_center_id, CAST(cr.cr_order_number AS varchar)) AS id,
               'FullJoin' AS source,
               d.d_year AS year
        FROM call_center cc
        FULL OUTER JOIN catalog_returns cr
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
    ),
    anti_returns AS (
        SELECT cc.cc_call_center_id
        FROM call_center cc
        WHERE NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_call_center_sk = cc.cc_call_center_sk
        )
    ),
    anti_rows AS (
        SELECT cc_call_center_id AS id,
               'NoReturn' AS source,
               NULL AS year
        FROM anti_returns
    ),
    array_vals AS (
        SELECT cc.cc_call_center_id AS id,
               CAST(val AS varchar) AS source,
               NULL AS year
        FROM call_center cc
        CROSS JOIN UNNEST(ARRAY[cc.cc_gmt_offset, cc.cc_tax_percentage]) AS t(val)
    )
SELECT id,
       source,
       year
FROM unique_recent_rows
UNION ALL
SELECT id,
       source,
       year
FROM full_join_rows
UNION ALL
SELECT id,
       source,
       year
FROM anti_rows
UNION ALL
SELECT id,
       source,
       year
FROM array_vals
ORDER BY year DESC NULLS LAST,
         id
OFFSET 10
LIMIT 100
