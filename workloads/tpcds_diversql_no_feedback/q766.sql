WITH sales_per_store AS (
   SELECT 
      s.s_store_id AS store_id,
      s.s_store_name AS store_name,
      d.d_year AS year,
      SUM(ss.ss_net_paid) AS total_amount,
      CAST('sale' AS varchar) AS transaction_type
   FROM store_sales ss
   RIGHT OUTER JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE (d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31')
      OR d.d_date IS NULL
   GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
returns_per_store AS (
   SELECT 
      s.s_store_id AS store_id,
      s.s_store_name AS store_name,
      d.d_year AS year,
      SUM(sr.sr_return_amt_inc_tax) AS total_amount,
      CAST('return' AS varchar) AS transaction_type
   FROM store_returns sr
   RIGHT OUTER JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN date_dim d
     ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE (d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31')
      OR d.d_date IS NULL
   GROUP BY s.s_store_id, s.s_store_name, d.d_year
)
SELECT store_id,
       store_name,
       year,
       transaction_type,
       total_amount
FROM sales_per_store
UNION ALL
SELECT store_id,
       store_name,
       year,
       transaction_type,
       total_amount
FROM returns_per_store
ORDER BY store_id,
         year DESC,
         transaction_type
LIMIT 100
