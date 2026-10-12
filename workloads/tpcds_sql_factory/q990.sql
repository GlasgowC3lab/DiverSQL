WITH store_return_summary AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_store_credit) AS total_store_credit,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS total_returns
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_id, s.s_store_name
),
store_return_flag AS (
    SELECT
        ss.*, 
        CASE WHEN ss.total_return_amt > 10000 THEN 'High' ELSE 'Normal' END AS return_volume_category
    FROM store_return_summary ss
),
store_reason_rank AS (
    SELECT
        s.s_store_id,
        sr.sr_reason_sk,
        COUNT(*) AS reason_cnt,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY COUNT(*) DESC) AS rn
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_id, sr.sr_reason_sk
),
store_closure AS (
    SELECT
        s.s_store_id,
        d_closure.d_year AS closed_year,
        CASE WHEN d_closure.d_year IS NULL THEN 'Open'
             WHEN d_closure.d_year < 2020 THEN 'Closed pre-2020'
             ELSE 'Closed post-2020' END AS closure_category
    FROM store s
    LEFT JOIN date_dim d_closure ON s.s_closed_date_sk = d_closure.d_date_sk
)
SELECT
    srff.s_store_id,
    srff.s_store_name,
    srff.total_return_amt,
    srff.total_refunded_cash,
    srff.total_store_credit,
    ROUND(srff.total_refunded_cash / NULLIF(srff.total_return_amt, 0), 4) AS cash_refund_ratio,
    ROUND(srff.total_store_credit / NULLIF(srff.total_return_amt, 0), 4) AS store_credit_ratio,
    srff.return_volume_category,
    srr.sr_reason_sk AS top_return_reason_sk,
    srr.reason_cnt AS top_reason_count,
    sc.closure_category
FROM store_return_flag srff
LEFT JOIN store_reason_rank srr ON srff.s_store_id = srr.s_store_id AND srr.rn = 1
LEFT JOIN store_closure sc ON srff.s_store_id = sc.s_store_id
ORDER BY srff.total_return_amt DESC
LIMIT 10
