WITH filtered AS (
    SELECT
        r.r_reason_desc,
        CASE
            WHEN sr.sr_return_amt > 100 THEN 'high'
            ELSE 'low'
        END AS amt_bucket,
        sr.sr_return_amt,
        sr.sr_net_loss,
        CONCAT(r.r_reason_id, ':', r.r_reason_desc) AS full_reason,
        SUBSTRING(r.r_reason_desc FROM 1 FOR 30) AS short_desc,
        REGEXP_EXTRACT(r.r_reason_desc, '(?i)(better.*price)') AS extracted_phrase
    FROM store_returns sr
    FULL OUTER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE (
            r.r_reason_desc IS NOT NULL
            AND REGEXP_LIKE(r.r_reason_desc, 'better.*price')
          )
          OR (
            r.r_reason_desc IS NOT NULL
            AND r.r_reason_desc LIKE '%color%'
          )
)
SELECT
    r_reason_desc,
    amt_bucket,
    COUNT(*) AS return_cnt,
    SUM(sr_return_amt) AS total_return_amt,
    SUM(sr_net_loss) AS total_net_loss,
    MAX(full_reason) AS example_full_reason,
    MAX(short_desc) AS example_short_desc,
    MAX(extracted_phrase) AS example_extracted_phrase
FROM filtered
GROUP BY CUBE (r_reason_desc, amt_bucket)
LIMIT 100
