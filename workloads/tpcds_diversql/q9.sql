WITH returns_by_year AS (
    SELECT
        CAST(d.d_year AS VARCHAR) AS period_year,
        'RETURN' AS metric_type,
        SUM(cr.cr_return_amount) AS amount,
        CASE WHEN SUM(cr.cr_return_amount) > 10000 THEN 'BIG' ELSE 'SMALL' END AS size_flag
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
    GROUP BY d.d_year
),
sales_by_year AS (
    SELECT
        CAST(d.d_year AS VARCHAR) AS period_year,
        'SALES' AS metric_type,
        SUM(ss.ss_net_paid) AS amount,
        CASE WHEN SUM(ss.ss_net_paid) > 50000 THEN 'BIG' ELSE 'SMALL' END AS size_flag
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'N'
    GROUP BY d.d_year
)
SELECT period_year,
       metric_type,
       amount,
       size_flag
FROM returns_by_year
UNION ALL
SELECT period_year,
       metric_type,
       amount,
       size_flag
FROM sales_by_year
ORDER BY period_year,
         metric_type
LIMIT 100
