WITH ss_agg AS (
  SELECT
    c.c_customer_sk,
    CONCAT(c.c_customer_id, '-', c.c_email_address) AS cust_key,
    SUM(ss.ss_net_paid) AS total_net_paid
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND regexp_like(c.c_email_address, '[A-Za-z0-9._%+-]+@[^@]+\\.com$')
  GROUP BY c.c_customer_sk, c.c_customer_id, c.c_email_address
),
ss AS (
  SELECT
    cust_key,
    CASE WHEN total_net_paid > 10000 THEN 'High'
         WHEN total_net_paid > 5000 THEN 'Medium'
         ELSE 'Low' END AS spend_category,
    total_net_paid,
    SUM(total_net_paid) OVER (ORDER BY total_net_paid DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
  FROM ss_agg
),
cs_agg AS (
  SELECT
    c.c_customer_sk,
    CONCAT(c.c_customer_id, '-', c.c_email_address) AS cust_key,
    SUM(cs.cs_net_paid) AS total_net_paid
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND c.c_email_address LIKE '%@example.com'
  GROUP BY c.c_customer_sk, c.c_customer_id, c.c_email_address
),
cs AS (
  SELECT
    cust_key,
    CASE WHEN total_net_paid > 10000 THEN 'High'
         WHEN total_net_paid > 5000 THEN 'Medium'
         ELSE 'Low' END AS spend_category,
    total_net_paid
  FROM cs_agg
),
excluded AS (
  SELECT
    CONCAT(c.c_customer_id, '-', c.c_email_address) AS cust_key
  FROM customer c
  WHERE substring(c.c_customer_id, 1, 3) = '999'
)
SELECT *
FROM (
  SELECT cust_key, spend_category, running_total
  FROM ss
  INTERSECT
  SELECT cust_key, spend_category, total_net_paid
  FROM cs
) AS intersected
EXCEPT
SELECT cust_key, CAST(NULL AS varchar), CAST(NULL AS double)
FROM excluded
LIMIT 100
