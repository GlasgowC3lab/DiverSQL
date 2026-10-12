WITH sales AS (
    SELECT
        td.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        MAX(ss.ss_net_profit) AS max_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
returns AS (
    SELECT
        td.t_hour,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_returns,
        MIN(wr.wr_net_loss) AS min_loss,
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
    s.total_discount,
    (s.total_sales - r.total_returns) AS net_sales,
    (s.max_profit - r.min_loss) AS profit_loss_gap,
    NTILE(4) OVER (PARTITION BY s.t_hour ORDER BY (s.total_sales - r.total_returns) DESC) AS quartile_bucket,
    CASE WHEN (s.total_sales - r.total_returns) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS net_sales_sign
FROM sales s
JOIN returns r ON s.t_hour = r.t_hour
ORDER BY s.t_hour, quartile_bucket
