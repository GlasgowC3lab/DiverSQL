WITH returns_by_page_meal AS (
    SELECT
        wp.wp_type,
        td.t_meal_time,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wp.wp_type, td.t_meal_time
    HAVING SUM(wr.wr_return_amt) > 0
)
SELECT
    rwp.wp_type,
    rwp.t_meal_time,
    rwp.total_return_amount,
    rwp.total_net_loss,
    rwp.avg_return_qty,
    CASE 
        WHEN rwp.total_net_loss > 1000 THEN 'HIGH_LOSS'
        WHEN rwp.total_net_loss BETWEEN 500 AND 1000 THEN 'MEDIUM_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    DENSE_RANK() OVER (PARTITION BY rwp.wp_type ORDER BY rwp.total_return_amount DESC) AS return_amount_rank
FROM returns_by_page_meal rwp
ORDER BY rwp.wp_type, return_amount_rank
