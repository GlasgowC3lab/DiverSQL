WITH reason_agg AS (
    SELECT
        r.r_reason_desc AS reason,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_fee) AS avg_fee,
        COUNT(DISTINCT sr.sr_store_sk) AS distinct_store_count
    FROM
        store_returns sr
    JOIN
        reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
        AND sr.sr_return_quantity > 0
    GROUP BY
        r.r_reason_desc
    HAVING
        SUM(sr.sr_net_loss) > 10000
)
SELECT
    reason,
    total_return_amount,
    total_refunded_cash,
    total_net_loss,
    avg_fee,
    distinct_store_count,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM
    reason_agg
ORDER BY
    net_loss_rank
LIMIT 20
