WITH cs_sales AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           SUM(cs.cs_net_paid) AS sales_amount,
           SUM(cs.cs_net_profit) AS profit_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cs.cs_bill_customer_sk
),
cs_returns AS (
    SELECT cr.cr_refunded_customer_sk AS customer_sk,
           SUM(cr.cr_return_amount) AS return_amount,
           SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cr.cr_refunded_customer_sk
),
ss_sales AS (
    SELECT ss.ss_customer_sk AS customer_sk,
           SUM(ss.ss_net_paid) AS sales_amount,
           SUM(ss.ss_net_profit) AS profit_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ss.ss_customer_sk
),
ss_returns AS (
    SELECT sr.sr_customer_sk AS customer_sk,
           SUM(sr.sr_return_amt) AS return_amount,
           SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY sr.sr_customer_sk
),
ws_sales AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_net_paid) AS sales_amount,
           SUM(ws.ws_net_profit) AS profit_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ws.ws_bill_customer_sk
),
ws_returns AS (
    SELECT wr.wr_refunded_customer_sk AS customer_sk,
           SUM(wr.wr_return_amt) AS return_amount,
           SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY wr.wr_refunded_customer_sk
)
SELECT
    c.c_customer_id,
    COALESCE(cs_sales.sales_amount, 0) + COALESCE(ss_sales.sales_amount, 0) + COALESCE(ws_sales.sales_amount, 0) AS total_sales,
    COALESCE(cs_returns.return_amount, 0) + COALESCE(ss_returns.return_amount, 0) + COALESCE(ws_returns.return_amount, 0) AS total_returns,
    CASE
        WHEN (COALESCE(cs_sales.sales_amount, 0) + COALESCE(ss_sales.sales_amount, 0) + COALESCE(ws_sales.sales_amount, 0)) > 0
        THEN (COALESCE(cs_returns.return_amount, 0) + COALESCE(ss_returns.return_amount, 0) + COALESCE(ws_returns.return_amount, 0)) /
             (COALESCE(cs_sales.sales_amount, 0) + COALESCE(ss_sales.sales_amount, 0) + COALESCE(ws_sales.sales_amount, 0))
        ELSE 0
    END AS return_rate
FROM customer c
LEFT JOIN cs_sales ON c.c_customer_sk = cs_sales.customer_sk
LEFT JOIN cs_returns ON c.c_customer_sk = cs_returns.customer_sk
LEFT JOIN ss_sales ON c.c_customer_sk = ss_sales.customer_sk
LEFT JOIN ss_returns ON c.c_customer_sk = ss_returns.customer_sk
LEFT JOIN ws_sales ON c.c_customer_sk = ws_sales.customer_sk
LEFT JOIN ws_returns ON c.c_customer_sk = ws_returns.customer_sk
WHERE (COALESCE(cs_sales.sales_amount, 0) + COALESCE(ss_sales.sales_amount, 0) + COALESCE(ws_sales.sales_amount, 0)) > 0
ORDER BY total_sales DESC
LIMIT 100
