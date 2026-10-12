WITH wr_agg AS (
    SELECT
        wr_returned_time_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr_return_quantity) AS avg_qty
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 20230101 AND 20231231
      AND wr_return_amt > 0
    GROUP BY wr_returned_time_sk
),
time_agg AS (
    SELECT
        t_time_sk,
        t_hour,
        t_shift,
        t_am_pm,
        CASE
            WHEN t_hour BETWEEN 0 AND 5 THEN 'Late Night'
            WHEN t_hour BETWEEN 6 AND 11 THEN 'Morning'
            WHEN t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS period
    FROM time_dim
    WHERE t_hour IS NOT NULL
)
SELECT
    period,
    t_shift,
    num_time_slots,
    sum_return_amt,
    sum_net_loss,
    avg_return_qty,
    RANK() OVER (ORDER BY sum_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        ta.period,
        ta.t_shift,
        COUNT(*) AS num_time_slots,
        SUM(wa.total_return_amt) AS sum_return_amt,
        SUM(wa.total_net_loss) AS sum_net_loss,
        AVG(wa.avg_qty) AS avg_return_qty
    FROM wr_agg wa
    JOIN time_agg ta ON wa.wr_returned_time_sk = ta.t_time_sk
    WHERE ta.t_shift IN ('Morning', 'Afternoon')
    GROUP BY ta.period, ta.t_shift
    HAVING SUM(wa.total_return_amt) > 10000
) agg
ORDER BY sum_net_loss DESC
LIMIT 50
