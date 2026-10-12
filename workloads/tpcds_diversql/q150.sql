WITH reason_processed AS (
    SELECT
        r_reason_sk,
        r_reason_desc,
        regexp_extract(r_reason_desc, '^(\\w+)', 1) AS first_word,
        substring(r_reason_desc, 1, 15) AS short_desc
    FROM reason
    WHERE r_reason_desc LIKE '%damaged%'
       OR regexp_like(r_reason_desc, '^Did not')
)
SELECT
    rp.r_reason_sk,
    rp.r_reason_desc,
    rp.first_word,
    rp.short_desc,
    COUNT(cr.cr_order_number) AS returns_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_ship_cost) AS avg_ship_cost
FROM catalog_returns cr
RIGHT OUTER JOIN reason_processed rp
    ON cr.cr_reason_sk = rp.r_reason_sk
GROUP BY
    rp.r_reason_sk,
    rp.r_reason_desc,
    rp.first_word,
    rp.short_desc
ORDER BY returns_cnt DESC
