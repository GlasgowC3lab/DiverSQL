WITH
    store_sales_summary AS (
        SELECT
            d.d_date AS sale_date,
            'Store' AS channel,
            SUM(ss.ss_net_paid) AS total_sales,
            CASE
                WHEN SUM(ss.ss_net_paid) > (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) THEN 'High'
                ELSE 'Low'
            END AS performance_flag
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_date
    ),
    catalog_sales_summary AS (
        SELECT
            d.d_date AS sale_date,
            'Catalog' AS channel,
            SUM(cs.cs_net_paid) AS total_sales,
            CASE
                WHEN SUM(cs.cs_net_paid) > (SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2) THEN 'High'
                ELSE 'Low'
            END AS performance_flag
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_date
    )
SELECT sale_date, channel, total_sales, performance_flag
FROM store_sales_summary
UNION
SELECT sale_date, channel, total_sales, performance_flag
FROM catalog_sales_summary
ORDER BY sale_date DESC, total_sales DESC
LIMIT 100
