WITH hourly_returns AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_fee) AS avg_fee,
        COUNT(*) AS return_cnt,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_customers
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND wr.wr_return_quantity > 0
    GROUP BY CUBE(t.t_hour, t.t_shift)
    HAVING SUM(wr.wr_return_amt) > 500
)
SELECT
    COALESCE(CAST(t_hour AS VARCHAR), 'ALL HOURS') AS hour,
    COALESCE(t_shift, 'ALL SHIFTS') AS shift,
    total_return_amt,
    total_return_amt_inc_tax,
    total_net_loss,
    avg_fee,
    return_cnt,
    distinct_customers,
    CASE WHEN total_return_amt > 0 THEN total_net_loss / total_return_amt ELSE NULL END AS loss_ratio
FROM hourly_returns
ORDER BY total_return_amt DESC
LIMIT 100
