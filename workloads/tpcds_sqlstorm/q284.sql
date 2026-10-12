WITH
cat_sales AS (
   SELECT 
       d.d_year,
       d.d_month_seq AS month,
       SUM(cs.cs_net_paid) AS sales_amount,
       COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE i.i_category = 'Sports' AND d.d_year = 2001
   GROUP BY d.d_year, d.d_month_seq
),
cat_returns AS (
   SELECT 
       d.d_year,
       d.d_month_seq AS month,
       SUM(cr.cr_return_amount) AS return_amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE i.i_category = 'Sports' AND d.d_year = 2001
   GROUP BY d.d_year, d.d_month_seq
),
store_sales AS (
   SELECT 
       d.d_year,
       d.d_month_seq AS month,
       SUM(ss.ss_net_paid) AS sales_amount,
       COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_category = 'Sports' AND d.d_year = 2001
   GROUP BY d.d_year, d.d_month_seq
),
store_returns_agg AS (
   SELECT 
       d.d_year,
       d.d_month_seq AS month,
       SUM(sr.sr_return_amt) AS return_amount
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE i.i_category = 'Sports' AND d.d_year = 2001
   GROUP BY d.d_year, d.d_month_seq
),
web_sales AS (
   SELECT 
       d.d_year,
       d.d_month_seq AS month,
       SUM(ws.ws_net_paid) AS sales_amount,
       COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE i.i_category = 'Sports' AND d.d_year = 2001
   GROUP BY d.d_year, d.d_month_seq
),
web_returns_agg AS (
   SELECT 
       d.d_year,
       d.d_month_seq AS month,
       SUM(wr.wr_return_amt) AS return_amount
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE i.i_category = 'Sports' AND d.d_year = 2001
   GROUP BY d.d_year, d.d_month_seq
)
SELECT
    channel,
    d_year,
    month,
    net_revenue,
    distinct_customers,
    RANK() OVER (PARTITION BY d_year, month ORDER BY net_revenue DESC) AS revenue_rank
FROM (
    SELECT
        'Catalog' AS channel,
        cs.d_year,
        cs.month,
        cs.sales_amount - COALESCE(cr.return_amount, 0) AS net_revenue,
        cs.distinct_customers
    FROM cat_sales cs
    LEFT JOIN cat_returns cr
      ON cs.d_year = cr.d_year AND cs.month = cr.month
    UNION ALL
    SELECT
        'Store' AS channel,
        ss.d_year,
        ss.month,
        ss.sales_amount - COALESCE(sr.return_amount, 0) AS net_revenue,
        ss.distinct_customers
    FROM store_sales ss
    LEFT JOIN store_returns_agg sr
      ON ss.d_year = sr.d_year AND ss.month = sr.month
    UNION ALL
    SELECT
        'Web' AS channel,
        ws.d_year,
        ws.month,
        ws.sales_amount - COALESCE(wr.return_amount, 0) AS net_revenue,
        ws.distinct_customers
    FROM web_sales ws
    LEFT JOIN web_returns_agg wr
      ON ws.d_year = wr.d_year AND ws.month = wr.month
) t
ORDER BY d_year, month, revenue_rank
