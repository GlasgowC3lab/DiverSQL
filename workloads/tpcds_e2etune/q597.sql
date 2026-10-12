WITH reason_returns AS (
    SELECT
        r.r_reason_desc,
        wr.wr_web_page_sk,
        COUNT(*) AS cnt_returns,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        AVG(wr.wr_return_tax) AS avg_tax,
        SUM(wr.wr_return_amt_inc_tax) AS sum_return_inc_tax
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 500
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY r.r_reason_desc, wr.wr_web_page_sk
)
SELECT
    rr.r_reason_desc,
    rr.wr_web_page_sk,
    rr.cnt_returns,
    rr.sum_return_amt,
    rr.avg_tax,
    rr.sum_return_inc_tax,
    RANK() OVER (ORDER BY rr.sum_return_amt DESC) AS amount_rank
FROM reason_returns rr
WHERE rr.cnt_returns >= 3
ORDER BY rr.sum_return_amt DESC
LIMIT 10
