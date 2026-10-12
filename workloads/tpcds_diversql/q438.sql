WITH sampled_sales AS (
    SELECT cs_sold_date_sk,
           cs_catalog_page_sk,
           cs_warehouse_sk,
           cs_ext_sales_price,
           cs_net_profit,
           cs_quantity
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2452000
),
dept_sales AS (
    SELECT cp.cp_department,
           SUM(ss.cs_ext_sales_price) AS total_sales,
           AVG(ss.cs_net_profit) AS avg_profit,
           COUNT(*) AS sales_cnt
    FROM sampled_sales ss
    JOIN catalog_page cp
      ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_department
    HAVING SUM(ss.cs_ext_sales_price) > 100000
),
dept_high_profit AS (
    SELECT cp.cp_department
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_net_profit > (SELECT AVG(cs_net_profit) FROM catalog_sales)
    GROUP BY cp.cp_department
    HAVING AVG(cs.cs_net_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales) * 1.2
)
SELECT dept
FROM (
    SELECT cp_department AS dept
    FROM dept_sales
    INTERSECT
    SELECT cp_department AS dept
    FROM dept_high_profit
) d
WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = d.dept
      AND inv.inv_quantity_on_hand > 500
)
LIMIT 100
