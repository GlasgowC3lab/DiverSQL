WITH sales_no_returns AS (
   SELECT
       cs.cs_order_number,
       cp.cp_department,
       d.d_year,
       cs.cs_net_paid,
       cs.cs_quantity
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE regexp_like(cp.cp_description, '\\d{3}')
     AND cp.cp_department LIKE 'Home%'
     AND NOT EXISTS (
         SELECT 1
         FROM catalog_returns cr
         WHERE cr.cr_order_number = cs.cs_order_number
     )
),

sales_cube AS (
   SELECT
       cp_department,
       d_year,
       SUM(cs_net_paid) AS total_net_paid,
       SUM(cs_quantity) AS total_quantity,
       CONCAT(cp_department, '-', CAST(d_year AS VARCHAR)) AS dept_year_key
   FROM sales_no_returns
   GROUP BY CUBE(cp_department, d_year)
)
SELECT
   cp_department,
   d_year,
   total_net_paid,
   total_quantity,
   dept_year_key
FROM sales_cube
EXCEPT
SELECT
   cp_department,
   d_year,
   total_net_paid,
   total_quantity,
   dept_year_key
FROM sales_cube
WHERE cp_department LIKE '%Clearance%'
ORDER BY total_net_paid DESC NULLS LAST
LIMIT 100
