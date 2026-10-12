WITH store_quarter_sales AS (
    SELECT
        d.d_fy_year,
        d.d_fy_quarter_seq,
        d.d_quarter_name,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS quarter_profit,
        AVG(ss.ss_ext_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_sold_date_sk) AS sales_days
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 2023
      AND d.d_weekend = 'N'
    GROUP BY d.d_fy_year, d.d_fy_quarter_seq, d.d_quarter_name, ss.ss_store_sk
)
SELECT
    sqs.d_fy_year,
    sqs.d_fy_quarter_seq,
    sqs.d_quarter_name,
    sqs.ss_store_sk,
    sqs.quarter_profit,
    sqs.avg_sales_price,
    sqs.sales_days,
    RANK() OVER (PARTITION BY sqs.d_fy_year, sqs.d_fy_quarter_seq ORDER BY sqs.quarter_profit DESC) AS profit_rank,
    SUM(sqs.quarter_profit) OVER (PARTITION BY sqs.ss_store_sk ORDER BY sqs.d_fy_year, sqs.d_fy_quarter_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM store_quarter_sales sqs
WHERE sqs.quarter_profit > 50000
ORDER BY sqs.d_fy_year, sqs.d_fy_quarter_seq, profit_rank
LIMIT 20
