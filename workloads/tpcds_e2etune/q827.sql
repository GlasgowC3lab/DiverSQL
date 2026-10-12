WITH sales_by_shift AS (
    SELECT
        t.t_shift,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt,
        AVG(ss.ss_quantity) AS avg_qty,
        SUM(ss.ss_coupon_amt) AS total_coupons
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2455000
      AND ss.ss_quantity > 30
    GROUP BY t.t_shift, t.t_hour
    HAVING SUM(ss.ss_ext_sales_price) > 1000
),
ranked_shifts AS (
    SELECT
        t_shift,
        t_hour,
        total_sales,
        total_profit,
        txn_cnt,
        avg_qty,
        total_coupons,
        RANK() OVER (PARTITION BY t_shift ORDER BY total_sales DESC) AS sales_rank
    FROM sales_by_shift
)
SELECT
    rs.t_shift,
    rs.t_hour,
    rs.total_sales,
    rs.total_profit,
    rs.txn_cnt,
    rs.avg_qty,
    rs.total_coupons,
    rs.sales_rank,
    (SELECT COUNT(*) FROM web_page WHERE wp_type = 'product') AS product_page_count
FROM ranked_shifts rs
WHERE rs.sales_rank <= 3
ORDER BY rs.t_shift, rs.sales_rank
