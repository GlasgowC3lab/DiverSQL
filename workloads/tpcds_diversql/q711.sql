WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store s
    RIGHT JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND d.d_current_month = 'Y'
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
),
years_dim AS (
    SELECT DISTINCT d.d_year
    FROM date_dim d
    WHERE d.d_current_month = 'Y'
    LIMIT 5
),
high_sales_dates AS (
    SELECT ss.ss_sold_date_sk AS date_sk
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_ext_sales_price > 8000
),
inventory_dates AS (
    SELECT inv.inv_date_sk AS date_sk
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    WHERE inv.inv_quantity_on_hand > 0
),
common_dates AS (
    SELECT date_sk FROM high_sales_dates
    INTERSECT
    SELECT date_sk FROM inventory_dates
)

SELECT
    sa.s_store_sk AS store_sk,
    sa.s_store_name AS store_name,
    sa.d_year AS sales_year,
    sa.total_sales,
    yd.d_year AS cross_year
FROM sales_agg sa
CROSS JOIN years_dim yd
WHERE EXISTS (
    SELECT 1
    FROM common_dates cd
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = cd.date_sk
    WHERE ss.ss_store_sk = sa.s_store_sk
)
UNION
SELECT
    sa2.s_store_sk,
    sa2.s_store_name,
    sa2.d_year,
    sa2.total_sales,
    yd2.d_year
FROM sales_agg sa2
CROSS JOIN years_dim yd2
WHERE sa2.total_sales IS NULL
ORDER BY store_sk, sales_year
LIMIT 100
