WITH sales AS (
    SELECT
        td.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_paid_inc_tax,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_sales_price BETWEEN 10 AND 500
    GROUP BY td.t_hour
),
returns AS (
    SELECT
        td.t_hour,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(wr.wr_account_credit) AS total_credit,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt > 0
    GROUP BY td.t_hour, wp.wp_type
)
SELECT
    s.t_hour,
    r.wp_type,
    s.total_sales,
    r.total_returns,
    s.total_paid_inc_tax,
    r.total_credit,
    (s.total_sales - r.total_returns) AS net_sales,
    (s.total_paid_inc_tax - r.total_credit) AS net_paid_inc_tax,
    CASE WHEN s.sales_cnt > r.returns_cnt THEN 'MORE_SALES' ELSE 'MORE_RETURNS' END AS volume_comparison,
    PERCENT_RANK() OVER (PARTITION BY s.t_hour ORDER BY (s.total_sales - r.total_returns) DESC) AS sales_percent_rank
FROM sales s
JOIN returns r ON s.t_hour = r.t_hour
ORDER BY s.t_hour, sales_percent_rank
