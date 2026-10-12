WITH combined_returns AS (
    SELECT i.i_category AS category,
           r.r_reason_desc AS reason_desc,
           sr.sr_return_amt AS return_amount
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 1

    UNION ALL

    SELECT i.i_category AS category,
           r.r_reason_desc AS reason_desc,
           cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 1
)
SELECT
    category,
    reason_desc,
    SUM(return_amount) AS total_return_amount,
    CASE
        WHEN SUM(return_amount) > 500 THEN 'High'
        ELSE 'Low'
    END AS loss_level
FROM combined_returns
GROUP BY ROLLUP (category, reason_desc)
ORDER BY total_return_amount DESC
LIMIT 100
