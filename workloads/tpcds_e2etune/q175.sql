WITH aggregated AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        t.t_hour,
        COUNT(*) AS total_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_quantity,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_customers,
        AVG(hd_returning.hd_vehicle_count) AS avg_returning_vehicle_count
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_refunded
      ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
      ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib
      ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND ib.ib_lower_bound >= 50000
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, t.t_hour
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    t_hour,
    total_returns,
    total_net_loss,
    total_quantity,
    avg_return_amount,
    distinct_customers,
    avg_returning_vehicle_count,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY t_hour, net_loss_rank
LIMIT 100
