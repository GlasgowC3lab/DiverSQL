WITH sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_current_month,
        d.d_date,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, d.d_year, d.d_current_month, d.d_date
),
store_ret AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
),
web_ret AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_transactions
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    s.s_store_name,
    sales.d_year,
    sales.d_current_month,
    sales.d_date,
    d_closed.d_date AS store_closed_date,
    sales.total_sales_amount,
    sales.total_sales_profit,
    COALESCE(store_ret.total_return_amount, 0) AS total_store_return_amount,
    COALESCE(store_ret.total_return_loss, 0) AS total_store_return_loss,
    COALESCE(web_ret.total_web_return_amount, 0) AS total_web_return_amount,
    COALESCE(web_ret.total_web_return_loss, 0) AS total_web_return_loss,
    sales.sales_transactions,
    COALESCE(store_ret.return_transactions, 0) AS store_return_transactions,
    COALESCE(web_ret.web_return_transactions, 0) AS web_return_transactions
FROM sales
JOIN store s ON sales.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN store_ret ON store_ret.sr_store_sk = s.s_store_sk
    AND store_ret.sr_returned_date_sk = sales.ss_sold_date_sk
LEFT JOIN web_ret ON web_ret.wr_returned_date_sk = sales.ss_sold_date_sk
ORDER BY sales.total_sales_profit DESC
LIMIT 100
