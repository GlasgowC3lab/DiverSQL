WITH filtered AS (
   SELECT
       ss.ss_store_sk,
       ss.ss_customer_sk,
       ss.ss_ext_sales_price,
       ss.ss_quantity,
       ss.ss_ext_discount_amt,
       ss.ss_net_paid,
       ss.ss_net_profit,
       c.c_customer_id,
       c.c_birth_month,
       c.c_preferred_cust_flag,
       s.s_store_name,
       s.s_gmt_offset,
       s.s_geography_class,
       s.s_suite_number
   FROM store_sales ss
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   WHERE s.s_gmt_offset = -5.00
     AND s.s_geography_class = 'Unknown'
     AND s.s_suite_number = 'Suite 100'
     AND c.c_birth_month = 7
     AND ss.ss_ext_discount_amt > 100.00
     AND ss.ss_quantity >= 2
),
aggregated AS (
   SELECT
       s_store_name,
       c_preferred_cust_flag,
       COUNT(*) AS transaction_count,
       SUM(ss_ext_sales_price) AS total_sales,
       AVG(ss_ext_sales_price) AS avg_sales,
       MIN(ss_ext_discount_amt) AS min_discount,
       MAX(ss_ext_discount_amt) AS max_discount,
       ROW_NUMBER() OVER (ORDER BY SUM(ss_ext_sales_price) DESC) AS row_num
   FROM filtered
   GROUP BY s_store_name, c_preferred_cust_flag
)
SELECT
   a.s_store_name,
   a.c_preferred_cust_flag,
   a.transaction_count,
   a.total_sales,
   a.avg_sales,
   a.min_discount,
   a.max_discount,
   a.row_num,
   d.discount_level
FROM aggregated a
CROSS JOIN (VALUES ('Low'), ('Medium'), ('High')) AS d(discount_level)
ORDER BY a.total_sales DESC, d.discount_level
LIMIT 100
