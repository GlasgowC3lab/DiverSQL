WITH ship_mode_summary AS (
    SELECT
        cr_ship_mode_sk,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity
    FROM catalog_returns
    WHERE cr_net_loss BETWEEN 50 AND 3000
      AND cr_return_quantity > 0
      AND cr_returned_time_sk BETWEEN 30000 AND 80000
    GROUP BY cr_ship_mode_sk
    HAVING COUNT(*) > 5
)
SELECT
    cr.cr_ship_mode_sk,
    cr.cr_returning_hdemo_sk,
    cr.cr_return_quantity,
    s.total_net_loss,
    s.return_cnt,
    s.avg_return_amount,
    s.total_return_quantity,
    RANK() OVER (ORDER BY s.total_net_loss DESC) AS net_loss_rank,
    PERCENT_RANK() OVER (ORDER BY s.avg_return_amount) AS avg_return_pct_rank
FROM catalog_returns cr
JOIN ship_mode_summary s
    ON cr.cr_ship_mode_sk = s.cr_ship_mode_sk
WHERE cr.cr_return_quantity > 1
  AND cr.cr_returned_time_sk BETWEEN 40000 AND 75000
GROUP BY
    cr.cr_ship_mode_sk,
    cr.cr_returning_hdemo_sk,
    cr.cr_return_quantity,
    s.total_net_loss,
    s.return_cnt,
    s.avg_return_amount,
    s.total_return_quantity
HAVING COUNT(*) > 2
ORDER BY s.total_net_loss DESC
LIMIT 100
