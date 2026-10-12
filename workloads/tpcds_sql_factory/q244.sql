WITH daily_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           SUM(cs.cs_net_paid_inc_tax) AS cs_daily_sales,
           SUM(cs.cs_net_profit) AS cs_daily_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
),
 daily_store AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           SUM(ss.ss_net_paid_inc_tax) AS ss_daily_sales,
           SUM(ss.ss_net_profit) AS ss_daily_profit
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk
),
 daily_returns AS (
    SELECT wr.wr_returned_date_sk AS date_sk,
           SUM(wr.wr_return_amt_inc_tax) AS wr_daily_returns,
           SUM(wr.wr_net_loss) AS wr_daily_loss
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
 daily_combined AS (
    SELECT COALESCE(cs.date_sk, ss.date_sk, wr.date_sk) AS date_sk,
           COALESCE(cs.cs_daily_sales, 0) + COALESCE(ss.ss_daily_sales, 0) AS total_sales,
           COALESCE(cs.cs_daily_profit, 0) + COALESCE(ss.ss_daily_profit, 0) AS total_profit,
           COALESCE(wr.wr_daily_returns, 0) AS total_returns,
           COALESCE(wr.wr_daily_loss, 0) AS total_return_loss
    FROM daily_sales cs
    FULL OUTER JOIN daily_store ss ON cs.date_sk = ss.date_sk
    FULL OUTER JOIN daily_returns wr ON COALESCE(cs.date_sk, ss.date_sk) = wr.date_sk
)
SELECT
    date_sk,
    total_sales,
    total_profit,
    total_returns,
    total_return_loss,
    total_sales - total_returns AS net_sales,
    total_profit - total_return_loss AS net_profit,
    CASE 
        WHEN total_profit - total_return_loss > 50000 THEN 'High'
        WHEN total_profit - total_return_loss > 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_bucket,
    SUM(total_sales) OVER (ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    SUM(total_profit) OVER (ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    RANK() OVER (ORDER BY total_return_loss DESC) AS return_loss_rank
FROM daily_combined
WHERE date_sk IS NOT NULL
ORDER BY date_sk
LIMIT 30
