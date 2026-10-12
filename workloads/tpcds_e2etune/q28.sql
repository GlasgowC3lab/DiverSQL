WITH reason_agg AS (
    SELECT
        r.r_reason_desc AS reason,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450996 AND 2451087
      AND wr.wr_return_amt > 0
    GROUP BY r.r_reason_desc
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    reason,
    total_returns,
    total_quantity,
    total_net_loss,
    avg_return_amount,
    total_refunded_cash,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM reason_agg
ORDER BY net_loss_rank
LIMIT 10
