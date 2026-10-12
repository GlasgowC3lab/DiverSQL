WITH sales_store AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_color = 'red'
    GROUP BY i.i_item_sk, i.i_category
),
sales_catalog AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_units = 'Box'
    GROUP BY i.i_item_sk, i.i_category
),
union_sales AS (
    SELECT i_item_sk, i_category, total_sales FROM sales_store
    UNION
    SELECT i_item_sk, i_category, total_sales FROM sales_catalog
)
SELECT i_item_sk,
       i_category,
       total_sales
FROM (
    SELECT
        i_item_sk,
        i_category,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS rn
    FROM union_sales
) ranked
WHERE rn <= 5
ORDER BY i_category, rn
