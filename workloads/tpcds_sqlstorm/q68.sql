WITH top_customers AS (
   SELECT ss1.ss_customer_sk AS customer_sk
   FROM store_sales ss1
   GROUP BY ss1.ss_customer_sk
   HAVING SUM(ss1.ss_net_paid) > 50000
), agg_sales AS (
   SELECT d.d_year AS d_year,
          i.i_category AS i_category,
          s.s_store_name AS s_store_name,
          SUM(ss.ss_net_paid) AS total_sales,
          COUNT(*) AS sales_count
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN top_customers tc ON ss.ss_customer_sk = tc.customer_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
   GROUP BY d.d_year, i.i_category, s.s_store_name
)
SELECT d_year,
       i_category,
       s_store_name,
       total_sales,
       sales_count,
       ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg_sales
ORDER BY d_year, sales_rank
LIMIT 100
