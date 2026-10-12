WITH sales AS (
    SELECT
        td.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
returns AS (
    SELECT
        td.t_hour,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY td.t_hour, wp.wp_type
)
SELECT
    s.t_hour,
    r.wp_type,
    s.total_sales,
    r.total_returns,
    s.total_profit,
    r.total_loss,
    (s.total_sales - r.total_returns) AS net_sales,
    (s.total_profit - r.total_loss) AS net_profit,
    CASE WHEN (s.total_profit - r.total_loss) > 0 THEN 'PROFITABLE' ELSE 'LOSS' END AS profit_status,
    RANK() OVER (PARTITION BY s.t_hour ORDER BY (s.total_profit - r.total_loss) DESC) AS page_profit_rank
FROM sales s
JOIN returns r ON s.t_hour = r.t_hour
ORDER BY s.t_hour, page_profit_rank
