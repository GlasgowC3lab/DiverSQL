WITH sales AS (
   SELECT cp.cp_type AS page_type,
          SUM(cs.cs_ext_sales_price) AS total_amount,
          COUNT(DISTINCT cs.cs_order_number) AS order_cnt
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cp.cp_type IN ('monthly', 'quarterly')
     AND hd.hd_vehicle_count > 0
     AND EXISTS (SELECT 1 FROM web_page wp WHERE wp.wp_customer_sk = c.c_customer_sk)
   GROUP BY cp.cp_type
),
returns AS (
   SELECT cp.cp_type AS page_type,
          -SUM(cr.cr_return_amount) AS total_amount,
          COUNT(DISTINCT cr.cr_order_number) AS order_cnt
   FROM catalog_returns cr
   JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cp.cp_type IN ('monthly', 'quarterly')
     AND hd.hd_vehicle_count > 0
     AND EXISTS (SELECT 1 FROM web_page wp WHERE wp.wp_customer_sk = c.c_customer_sk)
   GROUP BY cp.cp_type
)
SELECT page_type,
       total_amount,
       order_cnt
FROM sales
UNION ALL
SELECT page_type,
       total_amount,
       order_cnt
FROM returns
ORDER BY page_type, total_amount DESC
