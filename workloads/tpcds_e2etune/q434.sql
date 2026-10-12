WITH agg_returns AS (
    SELECT
        t.t_hour,
        t.t_shift,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_quantity
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 0 AND 23
      AND t.t_shift IS NOT NULL
    GROUP BY t.t_hour, t.t_shift
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    a.t_hour,
    a.t_shift,
    a.return_cnt,
    a.total_return_amt,
    a.total_net_loss,
    a.avg_quantity,
    (SELECT AVG(p_cost) FROM promotion p WHERE p.p_discount_active = 'N') AS avg_inactive_promo_cost,
    RANK() OVER (ORDER BY a.total_return_amt DESC) AS return_amt_rank
FROM agg_returns a
ORDER BY a.total_return_amt DESC
LIMIT 50
