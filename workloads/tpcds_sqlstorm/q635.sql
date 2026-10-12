WITH monthly_sales AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category = 'Sports'
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    ms.s_store_name,
    ms.d_year,
    ms.d_month_seq,
    ms.total_sales,
    ms.total_profit,
    ms.avg_discount,
    LAG(ms.total_sales) OVER (PARTITION BY ms.s_store_name ORDER BY ms.d_year, ms.d_month_seq) AS prev_month_sales,
    ms.total_sales - COALESCE(LAG(ms.total_sales) OVER (PARTITION BY ms.s_store_name ORDER BY ms.d_year, ms.d_month_seq), 0) AS sales_change
FROM monthly_sales ms
ORDER BY ms.total_sales DESC
LIMIT 100
