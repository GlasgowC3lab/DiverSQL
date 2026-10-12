WITH agg AS (
    SELECT
        t.t_hour,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451053
      AND r.r_reason_desc NOT LIKE '%Parts missing%'
    GROUP BY t.t_hour, r.r_reason_desc
)
SELECT
    t_hour,
    r_reason_desc,
    total_net_loss,
    total_refunded_cash,
    return_cnt,
    total_net_loss / SUM(total_net_loss) OVER (PARTITION BY t_hour) AS loss_share,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY t_hour, loss_rank
