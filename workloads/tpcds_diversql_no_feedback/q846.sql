WITH sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_ext_sales_price)               AS total_sales,
        SUM(cs.cs_quantity)                      AS total_quantity,
        AVG(cs.cs_sales_price)                   AS avg_sales_price
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000                     -- predicate 1
      AND cs.cs_ship_hdemo_sk IN (2581, 6203, 3129, 6854)    -- predicate 2
      AND cs.cs_quantity > 0                               -- predicate 3
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000   -- predicate 4
    GROUP BY cs.cs_catalog_page_sk, cs.cs_ship_hdemo_sk
),
cube_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_number,
        s.cs_ship_hdemo_sk,
        SUM(s.total_sales)          AS sum_sales,
        SUM(s.total_quantity)       AS sum_quantity,
        AVG(s.avg_sales_price)      AS avg_price
    FROM sales_agg s
    JOIN tpcds.catalog_page cp
        ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_number IN (1, 3, 7, 11, 20)           -- predicate 5
      AND cp.cp_end_date_sk >= 2450900                         -- predicate 6
      AND cp.cp_type = 'TYPE_A'                                -- predicate 7
      AND cp.cp_department IS NOT NULL                         -- predicate 8
    GROUP BY CUBE(cp.cp_department, cp.cp_catalog_number, s.cs_ship_hdemo_sk)
)
SELECT
    cp_department,
    cp_catalog_number,
    cs_ship_hdemo_sk,
    sum_sales,
    sum_quantity,
    avg_price,
    RANK() OVER (PARTITION BY cp_department ORDER BY sum_sales DESC)           AS dept_sales_rank,
    LAG(sum_sales) OVER (PARTITION BY cp_department ORDER BY sum_sales DESC)      AS prev_dept_sales,
    ROW_NUMBER() OVER (ORDER BY sum_sales DESC)                                 AS overall_rank
FROM cube_agg
ORDER BY sum_sales DESC
LIMIT 100
