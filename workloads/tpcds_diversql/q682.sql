WITH
  high_sales AS (
    SELECT
      c.c_customer_id,
      SUM(cs.cs_net_paid) AS total_paid,
      CASE
        WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High'
        WHEN SUM(cs.cs_net_paid) > 5000 THEN 'Medium'
        ELSE 'Low'
      END AS sales_category
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY c.c_customer_id
  ),
  store_sales_sample AS (
    SELECT
      c.c_customer_id,
      SUM(ss.ss_net_paid) AS total_paid,
      CASE
        WHEN SUM(ss.ss_net_paid) > 8000 THEN 'High'
        ELSE 'Low'
      END AS sales_category
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY c.c_customer_id
  ),
  union_customers AS (
    SELECT c_customer_id, total_paid, sales_category FROM high_sales
    UNION
    SELECT c_customer_id, total_paid, sales_category FROM store_sales_sample
  ),
  returned_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
  ),
  final_set AS (
    SELECT uc.c_customer_id, uc.total_paid, uc.sales_category
    FROM union_customers uc
    EXCEPT
    SELECT uc.c_customer_id, uc.total_paid, uc.sales_category
    FROM union_customers uc
    JOIN customer c ON c.c_customer_id = uc.c_customer_id
    JOIN returned_customers rc ON rc.cust_sk = c.c_customer_sk
  )
SELECT *
FROM final_set
ORDER BY total_paid DESC
OFFSET 0
LIMIT 100
