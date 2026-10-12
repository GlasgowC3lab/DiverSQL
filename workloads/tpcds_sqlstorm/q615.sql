WITH sales AS (
    SELECT s.s_store_sk,
           d.d_year,
           SUM(ss.ss_ext_sales_price) AS sales_amount,
           SUM(ss.ss_net_profit) AS profit_amount,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (1999, 2000, 2001)
    GROUP BY s.s_store_sk, d.d_year
), returns AS (
    SELECT sr.sr_store_sk,
           d.d_year,
           SUM(sr.sr_return_amt) AS return_amount,
           SUM(sr.sr_net_loss) AS net_loss_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year IN (1999, 2000, 2001)
    GROUP BY sr.sr_store_sk, d.d_year
)
SELECT s.s_store_name,
       sales.d_year,
       sales.sales_amount,
       COALESCE(returns.return_amount, 0) AS return_amount,
       sales.sales_amount - COALESCE(returns.return_amount, 0) AS net_sales,
       sales.profit_amount,
       sales.distinct_customers
FROM sales
LEFT JOIN returns ON sales.s_store_sk = returns.sr_store_sk AND sales.d_year = returns.d_year
JOIN store s ON sales.s_store_sk = s.s_store_sk
ORDER BY net_sales DESC
LIMIT 50
