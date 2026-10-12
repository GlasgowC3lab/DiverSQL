WITH returns_by_ship AS (
    SELECT cr_ship_mode_sk,
           SUM(cr_return_amount) AS total_return_amount,
           SUM(cr_net_loss) AS total_net_loss,
           AVG(cr_fee) AS avg_fee,
           COUNT(*) AS return_cnt,
           SUM(CASE WHEN cr_fee > 50 THEN 1 ELSE 0 END) AS high_fee_cnt
    FROM catalog_returns
    WHERE cr_returned_time_sk BETWEEN 30000 AND 60000
      AND cr_return_amount > 100
    GROUP BY cr_ship_mode_sk
    HAVING COUNT(*) >= 50
)
SELECT
    sm.sm_type,
    sm.sm_carrier,
    r.total_return_amount,
    r.total_net_loss,
    r.avg_fee,
    r.return_cnt,
    r.high_fee_cnt,
    (r.high_fee_cnt * 100.0 / r.return_cnt) AS high_fee_pct,
    RANK() OVER (ORDER BY r.total_net_loss DESC) AS net_loss_rank
FROM returns_by_ship r
JOIN ship_mode sm
  ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY net_loss_rank
LIMIT 100
