WITH hourly_sales AS (
    SELECT
        td.t_hour,
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour, ss.ss_store_sk
), ranked_sales AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY t_hour ORDER BY total_sales DESC) AS sales_rank,
        PERCENT_RANK() OVER (PARTITION BY t_hour ORDER BY total_profit DESC) AS profit_percentile
    FROM hourly_sales
    WHERE total_quantity >= 10
)
SELECT
    t_hour,
    ss_store_sk,
    total_sales,
    total_discount,
    total_profit,
    total_quantity,
    sales_rank,
    profit_percentile
FROM ranked_sales
ORDER BY t_hour, sales_rank
