WITH reason_store_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        sr.sr_store_sk AS store_sk,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty
    FROM
        store_returns sr
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
        AND sr.sr_return_amt > 0
    GROUP BY
        r.r_reason_desc,
        sr.sr_store_sk
    HAVING
        SUM(sr.sr_return_amt) > 500
),
ranked_reasons AS (
    SELECT
        reason_desc,
        store_sk,
        return_cnt,
        total_return_amt,
        total_net_loss,
        avg_return_qty,
        RANK() OVER (PARTITION BY store_sk ORDER BY total_net_loss DESC) AS net_loss_rank
    FROM reason_store_agg
)
SELECT
    reason_desc,
    store_sk,
    return_cnt,
    total_return_amt,
    total_net_loss,
    avg_return_qty,
    net_loss_rank
FROM ranked_reasons
WHERE total_net_loss > 1000
ORDER BY store_sk, net_loss_rank
LIMIT 200
