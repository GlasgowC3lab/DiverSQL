WITH catalog AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        i.i_category   AS category,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i   ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 0
),
web AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        i.i_category   AS category,
        wr.wr_return_amt AS return_amount
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i   ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > 0
),
combined AS (
    SELECT reason_desc, category, return_amount FROM catalog
    UNION ALL
    SELECT reason_desc, category, return_amount FROM web
)
SELECT
    COALESCE(reason_desc, 'ALL')        AS reason_desc,
    COALESCE(category,   'ALL')        AS category,
    SUM(return_amount)                 AS total_return_amount,
    GROUPING(reason_desc)              AS grp_reason,
    GROUPING(category)                 AS grp_category
FROM combined
GROUP BY GROUPING SETS (
    (reason_desc, category),
    (reason_desc),
    (category),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
