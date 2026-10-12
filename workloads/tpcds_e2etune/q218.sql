WITH reason_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_quantity
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2450300
      AND r.r_reason_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAACAAAAAAA')
    GROUP BY r.r_reason_desc
    HAVING SUM(wr.wr_return_amt_inc_tax) > 1000
)
SELECT
    reason_desc,
    num_returns,
    total_return_amount,
    total_net_loss,
    avg_quantity,
    ROUND((total_net_loss / NULLIF(total_return_amount, 0)) * 100, 2) AS loss_percent,
    ROUND((total_return_amount / SUM(total_return_amount) OVER ()) * 100, 2) AS percent_of_grand_total,
    SUM(total_return_amount) OVER () AS grand_total_return_amount
FROM reason_agg
ORDER BY total_return_amount DESC
LIMIT 50
