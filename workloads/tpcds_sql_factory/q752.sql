WITH store_sales_summary AS (
    SELECT
        ss.ss_store_sk,
        td.t_hour,
        COUNT(*) AS transactions,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_paid) AS total_paid,
        AVG(ss.ss_sales_price) AS avg_price
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY ss.ss_store_sk, td.t_hour
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    sss.ss_store_sk,
    sss.t_hour,
    sss.transactions,
    sss.total_sales,
    sss.total_discount,
    sss.total_paid,
    sss.avg_price,
    NTILE(4) OVER (PARTITION BY sss.t_hour ORDER BY sss.total_sales DESC) AS sales_quartile
FROM store_sales_summary sss
ORDER BY sss.t_hour, sales_quartile
