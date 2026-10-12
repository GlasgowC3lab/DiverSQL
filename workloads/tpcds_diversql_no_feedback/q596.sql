/*
Goal: Compare daily net sales and catalog return amounts, enrich each day with the number of distinct customers who bought in stores and the total catalog return amount for that day. Exclude any dates from the year 1999 and keep all days that appear in either sales or returns (full outer join). Limit to 100 rows.
*/
WITH sales_by_date AS (
    SELECT d.d_date AS trans_date,
           SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001               -- filter to a recent year for illustration
    GROUP BY d.d_date
),
returns_by_date AS (
    SELECT d.d_date AS trans_date,
           SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001               -- same year as sales for a fair comparison
    GROUP BY d.d_date
),
unioned_sales_returns AS (
    SELECT trans_date,
           total_sales,
           CAST(NULL AS decimal(7,2)) AS total_returns
    FROM sales_by_date
    UNION ALL
    SELECT trans_date,
           CAST(NULL AS decimal(7,2)) AS total_sales,
           total_returns
    FROM returns_by_date
),
store_summary AS (
    SELECT d.d_date AS trans_date,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
)
SELECT
    COALESCE(u.trans_date, s.trans_date) AS transaction_date,
    u.total_sales,
    u.total_returns,
    s.distinct_customers,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_date = COALESCE(u.trans_date, s.trans_date)
    ) AS total_return_amount_for_day
FROM unioned_sales_returns u
FULL OUTER JOIN store_summary s
    ON u.trans_date = s.trans_date
WHERE COALESCE(u.trans_date, s.trans_date) NOT IN (
    SELECT d3.d_date
    FROM date_dim d3
    WHERE d3.d_year = 1999
)
ORDER BY transaction_date DESC
LIMIT 100
