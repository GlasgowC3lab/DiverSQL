WITH
  store_customer_year AS (
    SELECT
      c.c_customer_id,
      d.d_year,
      SUM(ss.ss_ext_sales_price) AS total_spent,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn_year,
      RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rnk_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_ext_sales_price > 5000
    GROUP BY c.c_customer_id, d.d_year
  ),
  catalog_customer_year AS (
    SELECT
      c.c_customer_id,
      d.d_year,
      SUM(cs.cs_ext_sales_price) AS total_spent
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_sales_price > 5000
    GROUP BY c.c_customer_id, d.d_year
  ),
  diff AS (
    SELECT c_customer_id, d_year, total_spent, rn_year, rnk_year
    FROM store_customer_year
    EXCEPT
    SELECT c_customer_id, d_year, total_spent, CAST(NULL AS integer), CAST(NULL AS integer)
    FROM catalog_customer_year
  )
SELECT
  d.c_customer_id,
  d.d_year,
  d.total_spent,
  d.rn_year,
  d.rnk_year,
  ROW_NUMBER() OVER (ORDER BY d.total_spent DESC) AS global_row_num
FROM diff d
ORDER BY d.d_year DESC, d.total_spent DESC
LIMIT 100
