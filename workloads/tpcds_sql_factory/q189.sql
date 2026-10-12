WITH page_meal_stats AS (
    SELECT
        wp.wp_type,
        t.t_meal_time,
        t.t_hour,
        COUNT(*) AS ret_cnt,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_inc_tax,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_return_quantity) AS total_qty
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wp.wp_type, t.t_meal_time, t.t_hour
    HAVING COUNT(*) > 5
)
SELECT
    wp_type,
    t_meal_time,
    ret_cnt,
    avg_return_inc_tax,
    avg_net_loss,
    DENSE_RANK() OVER (PARTITION BY t_meal_time ORDER BY avg_net_loss DESC) AS net_loss_rank_by_meal,
    SUM(total_qty) OVER (PARTITION BY wp_type ORDER BY t_hour
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_qty_last_3_hours,
    CASE
        WHEN avg_net_loss > 2000 THEN 'ALERT'
        ELSE 'NORMAL'
    END AS risk_flag
FROM page_meal_stats
ORDER BY wp_type, t_meal_time
