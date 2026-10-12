WITH returns_by_time AS (
    SELECT
        wr.wr_returned_time_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    WHERE wr.wr_returned_time_sk IS NOT NULL
    GROUP BY wr.wr_returned_time_sk
),
aggregated AS (
    SELECT
        t.t_hour,
        t.t_shift,
        t.t_meal_time,
        SUM(r.total_return_amt) AS sum_return_amt,
        AVG(r.avg_return_amt) AS avg_return_amt,
        SUM(r.total_quantity) AS sum_quantity,
        SUM(r.total_net_loss) AS sum_net_loss,
        SUM(r.return_cnt) AS total_returns
    FROM returns_by_time r
    JOIN time_dim t
        ON r.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 1 AND 3
      AND t.t_shift IN ('first', 'second')
    GROUP BY t.t_hour, t.t_shift, t.t_meal_time
)
SELECT
    a.t_hour,
    a.t_shift,
    a.t_meal_time,
    a.sum_return_amt,
    a.avg_return_amt,
    a.sum_quantity,
    a.sum_net_loss,
    a.total_returns,
    RANK() OVER (PARTITION BY a.t_hour ORDER BY a.sum_net_loss DESC) AS net_loss_rank
FROM aggregated a
ORDER BY a.t_hour, net_loss_rank
