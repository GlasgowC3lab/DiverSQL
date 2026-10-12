WITH hourly_zip AS (
    SELECT
        ca.ca_zip,
        t.t_hour,
        SUM(wr.wr_net_loss) AS net_loss_sum,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_net_loss) AS avg_net_loss
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY ca.ca_zip, t.t_hour
)
SELECT
    ca_zip,
    t_hour,
    net_loss_sum,
    return_cnt,
    avg_net_loss,
    SUM(net_loss_sum) OVER (PARTITION BY ca_zip ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
    AVG(net_loss_sum) OVER (PARTITION BY ca_zip ORDER BY t_hour
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_net_loss_last_3_hours,
    CASE
        WHEN avg_net_loss > 2000 THEN 'ALERT'
        ELSE 'NORMAL'
    END AS risk_level
FROM hourly_zip
ORDER BY ca_zip, t_hour
