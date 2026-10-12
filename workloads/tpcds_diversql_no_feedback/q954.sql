WITH cc_sales AS (
   SELECT
       cc.cc_call_center_id AS entity_id,
       d.d_year AS year,
       SUM(cs.cs_ext_sales_price) AS sales,
       COUNT(*) AS orders,
       'CallCenter' AS entity_type
   FROM catalog_sales cs
   RIGHT JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE cc.cc_state = 'CA'
     AND d.d_year BETWEEN 1999 AND 2001
   GROUP BY cc.cc_call_center_id, d.d_year
),
wh_sales AS (
   SELECT
       w.w_warehouse_id AS entity_id,
       d.d_year AS year,
       SUM(cs.cs_ext_sales_price) AS sales,
       COUNT(*) AS orders,
       'Warehouse' AS entity_type
   FROM catalog_sales cs
   RIGHT JOIN warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE w.w_state = 'CA'
     AND d.d_year BETWEEN 1999 AND 2001
   GROUP BY w.w_warehouse_id, d.d_year
),
union_data AS (
   SELECT * FROM cc_sales
   UNION ALL
   SELECT * FROM wh_sales
)
SELECT
   entity_type,
   entity_id,
   year,
   SUM(sales) AS total_sales,
   SUM(orders) AS total_orders,
   CASE
       WHEN entity_type = 'CallCenter' THEN (
           SELECT COUNT(DISTINCT cs2.cs_catalog_page_sk)
           FROM catalog_sales cs2
           JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
           WHERE cc2.cc_call_center_id = union_data.entity_id
       )
       WHEN entity_type = 'Warehouse' THEN (
           SELECT COUNT(DISTINCT cs2.cs_catalog_page_sk)
           FROM catalog_sales cs2
           JOIN warehouse w2 ON cs2.cs_warehouse_sk = w2.w_warehouse_sk
           WHERE w2.w_warehouse_id = union_data.entity_id
       )
       ELSE 0
   END AS distinct_catalog_pages
FROM union_data
GROUP BY ROLLUP(entity_type, entity_id, year)
ORDER BY entity_type, entity_id, year
LIMIT 100
