WITH hourly_shift_agg AS (
    SELECT
        td.t_hour,
        td.t_shift,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_tax) AS avg_return_tax
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_item_sk IN (96650, 118185, 92064)
      AND sr.sr_return_tax BETWEEN 2.00 AND 30.00
      AND sr.sr_store_sk IN (163, 733, 298)
      AND td.t_shift IS NOT NULL
    GROUP BY td.t_hour, td.t_shift
)
SELECT
    t_hour,
    t_shift,
    return_cnt,
    total_return_amt,
    total_net_loss,
    avg_return_tax,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM hourly_shift_agg
WHERE total_return_amt > 500
ORDER BY net_loss_rank
LIMIT 10
