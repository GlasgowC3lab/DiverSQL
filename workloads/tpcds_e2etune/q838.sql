SELECT
    q.t_hour,
    q.r_reason_desc,
    q.returns_cnt,
    q.total_net_loss,
    q.avg_return_amt
FROM (
    SELECT
        t.t_hour AS t_hour,
        r.r_reason_desc AS r_reason_desc,
        COUNT(*) AS returns_cnt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        ROW_NUMBER() OVER (PARTITION BY t.t_hour ORDER BY SUM(sr.sr_net_loss) DESC) AS rn
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND sr.sr_store_credit > 0
    GROUP BY t.t_hour, r.r_reason_desc
    HAVING COUNT(*) >= 5
) q
WHERE q.rn = 1
ORDER BY q.t_hour
