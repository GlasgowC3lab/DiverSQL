WITH sales AS (
    SELECT
        td.t_hour,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
        AVG(ss.ss_sales_price) AS avg_price,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_quantity > 1
    GROUP BY td.t_hour
),
returns AS (
    SELECT
        td.t_hour,
        wp.wp_type,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns_inc_tax,
        COUNT(*) FILTER (WHERE wr.wr_fee > 0) AS fee_return_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_quantity >= 1
    GROUP BY td.t_hour, wp.wp_type
)
SELECT
    s.t_hour,
    r.wp_type,
    s.tickets_sold,
    s.avg_price,
    s.total_sales,
    r.total_returns_inc_tax,
    r.fee_return_cnt,
    (s.total_sales - r.total_returns_inc_tax) AS net_sales,
    RANK() OVER (PARTITION BY s.t_hour ORDER BY (s.total_sales - r.total_returns_inc_tax) DESC) AS sales_rank
FROM sales s
JOIN returns r ON s.t_hour = r.t_hour
ORDER BY s.t_hour, sales_rank
