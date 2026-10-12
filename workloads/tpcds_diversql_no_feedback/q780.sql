WITH sales_data AS (
   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       SUM(cs.cs_net_paid) AS amount,
       (SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk) AS avg_warehouse_sales
   FROM catalog_sales cs
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND w.w_street_type = 'Ave'
     AND NOT EXISTS (
         SELECT 1
         FROM catalog_returns cr
         JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
         WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
           AND r.r_reason_desc = 'Defective'
     )
   GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_warehouse_sk
   HAVING SUM(cs.cs_net_paid) > 100000
),
returns_data AS (
   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       SUM(cr.cr_return_amount) * -1 AS amount,
       CAST(NULL AS double) AS avg_warehouse_sales
   FROM catalog_returns cr
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2001
     AND r.r_reason_desc LIKE '%Damaged%'
   GROUP BY w.w_warehouse_id, w.w_warehouse_name
   HAVING SUM(cr.cr_return_amount) > 5000
)
SELECT *
FROM (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
) combined
ORDER BY amount DESC
LIMIT 100
