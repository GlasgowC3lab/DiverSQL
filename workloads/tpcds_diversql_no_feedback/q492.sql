WITH store_ret AS (
        SELECT
            r.r_reason_desc AS reason_desc,
            SUM(sr.sr_return_amt) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_fy_quarter_seq = 5
        GROUP BY r.r_reason_desc
    ),
    web_ret AS (
        SELECT
            r.r_reason_desc AS reason_desc,
            SUM(wr.wr_return_amt) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_fy_quarter_seq = 5
        GROUP BY r.r_reason_desc
    ),
    union_ret AS (
        SELECT reason_desc, total_return_amount, return_cnt, 'store' AS source FROM store_ret
        UNION ALL
        SELECT reason_desc, total_return_amount, return_cnt, 'web'   AS source FROM web_ret
    ),
    small_dim AS (
        SELECT d.d_fy_week_seq, d.d_fy_quarter_seq
        FROM date_dim d
        WHERE d.d_fy_quarter_seq = 5
        LIMIT 5
    )
SELECT
    sd.d_fy_week_seq,
    ur.reason_desc,
    ur.total_return_amount,
    ur.return_cnt,
    ur.source
FROM small_dim sd
CROSS JOIN union_ret ur
LIMIT 100
