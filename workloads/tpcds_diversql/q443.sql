-- Goal: Identify top reason‑income band combinations for returns that involve a "working" related reason in stores or a "job" related reason online, sampling store data, using full outer join, anti‑semi join, string processing and union aggregation.
WITH store_part AS (
    SELECT
        CONCAT(r.r_reason_id, '-', SUBSTRING(r.r_reason_desc, 1, 10)) AS reason_key,
        hd.hd_income_band_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt
    FROM (SELECT * FROM store_returns TABLESAMPLE BERNOULLI (10)) sr
    FULL OUTER JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'working')
    GROUP BY
        CONCAT(r.r_reason_id, '-', SUBSTRING(r.r_reason_desc, 1, 10)),
        hd.hd_income_band_sk
),
web_part AS (
    SELECT
        CONCAT(r.r_reason_id, '-', SUBSTRING(r.r_reason_desc, 1, 10)) AS reason_key,
        hd.hd_income_band_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc LIKE '%job%' AND wr.wr_return_tax > 10
    GROUP BY
        CONCAT(r.r_reason_id, '-', SUBSTRING(r.r_reason_desc, 1, 10)),
        hd.hd_income_band_sk
),
union_all AS (
    SELECT reason_key, hd_income_band_sk, total_return_amt, cnt FROM store_part
    UNION DISTINCT
    SELECT reason_key, hd_income_band_sk, total_return_amt, cnt FROM web_part
)
SELECT
    reason_key,
    hd_income_band_sk,
    SUM(total_return_amt) AS agg_return_amt,
    SUM(cnt) AS total_cnt
FROM union_all
WHERE reason_key NOT IN (
    SELECT CONCAT(r_reason_id, '-', SUBSTRING(r_reason_desc, 1, 10))
    FROM reason
    WHERE r_reason_desc LIKE '%color%'
)
GROUP BY reason_key, hd_income_band_sk
ORDER BY agg_return_amt DESC
LIMIT 100
