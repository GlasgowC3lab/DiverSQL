WITH hourly_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        td.t_hour,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_return_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, td.t_hour
)
SELECT
    ha.s_store_id,
    ha.s_store_name,
    ha.s_city,
    ha.t_hour,
    ha.total_return_quantity,
    ha.total_return_amount_inc_tax,
    ha.total_net_loss,
    ha.preferred_return_count,
    SUM(ha.total_net_loss) OVER (PARTITION BY ha.s_store_id ORDER BY ha.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
    RANK() OVER (PARTITION BY ha.s_store_id ORDER BY ha.total_net_loss DESC) AS net_loss_hour_rank
FROM hourly_agg ha
ORDER BY ha.s_store_id, ha.t_hour
