WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
sub1 AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_ext_discount_amt > 500
),
sub2 AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_ext_tax > 200
),
intersect_orders AS (
    SELECT cs_order_number FROM sub1
    INTERSECT
    SELECT cs_order_number FROM sub2
),
agg_sales AS (
    SELECT cs_catalog_page_sk,
           cs_order_number,
           SUM(cs_ext_sales_price) AS total_sales,
           COUNT(*) AS txn_count
    FROM sampled_sales
    WHERE cs_ext_sales_price > 1000
      AND cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
    GROUP BY cs_catalog_page_sk, cs_order_number
),
ranked_sales AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY cs_catalog_page_sk ORDER BY total_sales DESC) AS rnk
    FROM agg_sales
),
top_sales AS (
    SELECT cs_catalog_page_sk,
           cs_order_number,
           total_sales,
           txn_count
    FROM ranked_sales
    WHERE rnk <= 5
),
filtered_page AS (
    SELECT cp_catalog_page_sk,
           cp_type,
           cp_department,
           cp_catalog_page_number,
           cp_description,
           CONCAT(cp_type, '_', cp_department) AS page_label,
           REGEXP_EXTRACT(cp_description, '(sale|discount|offer)', 1) AS keyword
    FROM catalog_page
    WHERE REGEXP_LIKE(cp_description, 'sale|discount|offer')
      AND cp_type LIKE 'qu%'
)
SELECT 
    fp.cp_catalog_page_number,
    fp.cp_type,
    fp.page_label,
    fp.keyword,
    ts.cs_order_number,
    ts.total_sales,
    ts.txn_count
FROM filtered_page fp
FULL OUTER JOIN top_sales ts
    ON fp.cp_catalog_page_sk = ts.cs_catalog_page_sk
WHERE (fp.cp_description LIKE '%sale%' OR fp.cp_description LIKE '%discount%')
ORDER BY fp.cp_catalog_page_number ASC, ts.total_sales DESC
LIMIT 100
