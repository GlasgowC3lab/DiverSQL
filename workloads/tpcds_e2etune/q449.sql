WITH agg AS (
    SELECT
        td.t_hour,
        td.t_shift,
        wp.wp_type,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_qty
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND wp.wp_type IS NOT NULL
    GROUP BY td.t_hour, td.t_shift, wp.wp_type
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    agg.t_hour,
    agg.t_shift,
    agg.wp_type,
    agg.return_cnt,
    agg.total_return_amt,
    agg.total_net_loss,
    agg.avg_qty,
    RANK() OVER (ORDER BY agg.total_return_amt DESC) AS return_rank
FROM agg
ORDER BY agg.total_return_amt DESC
LIMIT 50
