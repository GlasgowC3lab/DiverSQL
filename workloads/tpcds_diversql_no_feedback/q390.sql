WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_fee,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)not')
      AND cp.cp_description LIKE '%sale%'
)
SELECT
    r_desc,
    first_word,
    SUM(return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(fee) AS avg_fee
FROM (
    SELECT
        cr_return_amount AS return_amount,
        cr_fee AS fee,
        r_reason_desc AS r_desc,
        regexp_extract(r_reason_desc, '^(\\w+)', 1) AS first_word
    FROM filtered_returns
) sub
GROUP BY r_desc, first_word
ORDER BY total_return_amount DESC
LIMIT 100
