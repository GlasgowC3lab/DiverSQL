WITH wr_agg AS (
    SELECT
        wr_reason_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_refunded_cash) AS total_refunded_cash,
        AVG(wr_return_quantity) AS avg_return_qty
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND wr_return_amt > 10
      AND wr_refunded_customer_sk > 5000000
      AND wr_return_tax IS NOT NULL
    GROUP BY wr_reason_sk
),
joined AS (
    SELECT
        reason.r_reason_id,
        reason.r_reason_desc,
        wr_agg.return_cnt,
        wr_agg.total_return_amt,
        wr_agg.total_refunded_cash,
        wr_agg.avg_return_qty,
        substr(reason.r_reason_id, 1, 1) AS reason_prefix,
        ROW_NUMBER() OVER (
            PARTITION BY substr(reason.r_reason_id, 1, 1)
            ORDER BY wr_agg.total_return_amt DESC
        ) AS rn
    FROM wr_agg
    JOIN reason
        ON wr_agg.wr_reason_sk = reason.r_reason_sk
    WHERE reason.r_reason_desc LIKE '%working%'
)
SELECT
    r_reason_id,
    r_reason_desc,
    return_cnt,
    total_return_amt,
    total_refunded_cash,
    avg_return_qty,
    reason_prefix,
    rn
FROM joined
WHERE rn <= 3
ORDER BY reason_prefix, rn
LIMIT 100
