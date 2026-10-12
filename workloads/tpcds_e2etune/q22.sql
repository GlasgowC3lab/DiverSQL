WITH cust_sales AS (
  SELECT
    ss_customer_sk,
    SUM(ss_net_paid_inc_tax) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(ss_ext_discount_amt) AS total_discount,
    COUNT(*) AS transaction_count,
    MIN(ss_sold_date_sk) AS first_sale_date,
    MAX(ss_sold_date_sk) AS last_sale_date
  FROM store_sales
  WHERE ss_sold_date_sk BETWEEN 2450000 AND 2452000
    AND ss_quantity > 0
  GROUP BY ss_customer_sk
  HAVING COUNT(*) > 5
)
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  c.c_salutation,
  c.c_birth_month,
  cs.total_sales,
  cs.total_profit,
  cs.transaction_count,
  RANK() OVER (PARTITION BY c.c_birth_month ORDER BY cs.total_sales DESC) AS sales_rank_by_birth_month
FROM cust_sales cs
JOIN customer c
  ON cs.ss_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1970 AND 1990
ORDER BY cs.total_sales DESC
LIMIT 20
