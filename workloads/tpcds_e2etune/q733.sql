WITH hourly_stats AS (
    SELECT 
        t.t_hour,
        t.t_meal_time,
        COUNT(*) AS cnt_returns,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        SUM(wr.wr_net_loss) AS sum_net_loss,
        AVG(wr.wr_return_quantity) AS avg_qty,
        SUM(wr.wr_fee) AS sum_fee,
        MAX(wr.wr_return_amt) AS max_return_amt,
        MIN(wr.wr_return_amt) AS min_return_amt
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE wr.wr_return_amt BETWEEN 20 AND 500
      AND t.t_shift = 'Evening'
    GROUP BY t.t_hour, t.t_meal_time
)
SELECT 
    h.t_hour,
    h.t_meal_time,
    h.cnt_returns,
    h.sum_return_amt,
    h.sum_net_loss,
    h.avg_qty,
    h.sum_fee,
    h.max_return_amt,
    h.min_return_amt,
    RANK() OVER (ORDER BY h.sum_net_loss DESC) AS net_loss_rank
FROM hourly_stats h
WHERE h.sum_net_loss > 10000
ORDER BY h.sum_net_loss DESC
LIMIT 100
