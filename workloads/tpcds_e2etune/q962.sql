WITH agg AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_return_tax) AS total_return_tax
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 20
        AND t.t_meal_time IN ('Lunch', 'Dinner')
        AND wr.wr_return_amt > 0
    GROUP BY t.t_hour, t.t_shift
)
SELECT
    a.t_hour,
    a.t_shift,
    a.total_return_amt,
    a.cnt_returns,
    a.avg_return_amt,
    a.total_fee,
    a.total_return_tax,
    RANK() OVER (PARTITION BY a.t_shift ORDER BY a.total_return_amt DESC) AS rank_within_shift,
    ROUND(a.total_return_amt / NULLIF(a.cnt_returns, 0), 2) AS avg_return_per_txn
FROM agg a
ORDER BY a.total_return_amt DESC
LIMIT 20
