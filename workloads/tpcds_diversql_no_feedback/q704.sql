WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        SUM(c.cs_ext_sales_price) AS total_sales,
        AVG(c.cs_ext_discount_amt) AS avg_discount,
        'catalog' AS sales_channel
    FROM catalog_sales c
    FULL OUTER JOIN date_dim d
        ON c.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
),
store_agg AS (
    SELECT
        d.d_year AS year,
        SUM(s.ss_ext_sales_price) AS total_sales,
        AVG(s.ss_ext_discount_amt) AS avg_discount,
        'store' AS sales_channel
    FROM store_sales s
    FULL OUTER JOIN date_dim d
        ON s.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
)
SELECT year,
       total_sales,
       avg_discount,
       sales_channel
FROM catalog_agg
UNION ALL
SELECT year,
       total_sales,
       avg_discount,
       sales_channel
FROM store_agg
ORDER BY year DESC,
         total_sales DESC
LIMIT 100
