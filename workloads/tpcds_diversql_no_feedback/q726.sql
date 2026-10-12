WITH daily_sales AS (
    SELECT CAST(d.d_date AS VARCHAR) AS entity,
           COALESCE(SUM(ss.ss_ext_sales_price), 0) AS metric,
           'Store Sales Daily' AS source
    FROM date_dim d
    RIGHT OUTER JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date
),
store_quantity AS (
    SELECT s.s_store_name AS entity,
           COALESCE(SUM(ss.ss_quantity), 0) AS metric,
           'Store Quantity' AS source
    FROM store s
    FULL OUTER JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 OR d.d_year IS NULL
    GROUP BY s.s_store_name
)
SELECT entity, metric, source
FROM daily_sales
UNION ALL
SELECT entity, metric, source
FROM store_quantity
ORDER BY metric DESC
LIMIT 100
