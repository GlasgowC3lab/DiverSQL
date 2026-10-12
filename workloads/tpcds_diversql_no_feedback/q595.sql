WITH catalog_data AS (
    SELECT
        'catalog' AS source_type,
        r.r_reason_desc AS reason_desc,
        cr.cr_return_amount AS return_amount,
        split(r.r_reason_desc, ' ') AS words
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
),
catalog_unnested AS (
    SELECT
        source_type,
        reason_desc,
        w.word,
        return_amount
    FROM catalog_data
    CROSS JOIN UNNEST(words) AS w(word)
),
store_data AS (
    SELECT
        'store' AS source_type,
        r.r_reason_desc AS reason_desc,
        sr.sr_return_amt AS return_amount,
        split(r.r_reason_desc, ' ') AS words
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
),
store_unnested AS (
    SELECT
        source_type,
        reason_desc,
        w.word,
        return_amount
    FROM store_data
    CROSS JOIN UNNEST(words) AS w(word)
),
unioned AS (
    SELECT * FROM catalog_unnested
    UNION ALL
    SELECT * FROM store_unnested
)
SELECT
    source_type,
    reason_desc,
    word,
    SUM(return_amount) AS total_return_amount,
    GROUPING(source_type) AS g_source,
    GROUPING(reason_desc) AS g_reason,
    GROUPING(word) AS g_word
FROM unioned
GROUP BY ROLLUP(source_type, reason_desc, word)
ORDER BY source_type, reason_desc, word
LIMIT 100
