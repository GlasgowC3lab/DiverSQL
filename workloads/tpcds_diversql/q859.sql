WITH sales_items AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_item_desc,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_txn,
    CASE
      WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH'
      WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS sales_category
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
    AND regexp_like(i.i_item_desc, '^[A-Za-z]+[0-9]{2}$')
  GROUP BY i.i_item_sk, i.i_product_name, i.i_item_desc
),

web_sales_items AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_item_desc,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_txn,
    CASE
      WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'HIGH'
      WHEN SUM(ws.ws_ext_sales_price) > 50000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS sales_category
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
    AND i.i_item_desc LIKE '%-%'
  GROUP BY i.i_item_sk, i.i_product_name, i.i_item_desc
),

union_sales AS (
  SELECT i_item_sk, i_product_name, i_item_desc, total_sales, sales_txn, sales_category
  FROM sales_items
  UNION
  SELECT i_item_sk, i_product_name, i_item_desc, total_sales, sales_txn, sales_category
  FROM web_sales_items
),

customer_store AS (
  SELECT DISTINCT ss.ss_customer_sk AS cust_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
),

customer_web AS (
  SELECT DISTINCT ws.ws_bill_customer_sk AS cust_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
),

common_customers AS (
  SELECT cust_sk FROM customer_store
  INTERSECT
  SELECT cust_sk FROM customer_web
),

date_one AS (
  SELECT d.d_date_sk
  FROM date_dim d
  WHERE d.d_date = DATE '2000-01-01'
),

num_set AS (
  SELECT val AS n FROM UNNEST(ARRAY[1,2,3]) AS t(val)
),

cross_grid AS (
  SELECT d.d_date_sk, n
  FROM date_one d
  CROSS JOIN num_set
),

final_items AS (
  SELECT
    us.i_item_sk,
    us.i_product_name,
    us.i_item_desc,
    us.total_sales,
    us.sales_txn,
    us.sales_category,
    lc.prefix
  FROM union_sales us
  LEFT JOIN LATERAL (
    SELECT substring(us.i_product_name FROM 1 FOR 3) AS prefix
  ) lc ON TRUE
)
SELECT
  fi.i_item_sk,
  fi.i_product_name,
  fi.prefix,
  fi.total_sales,
  fi.sales_category,
  CASE
    WHEN fi.sales_category = 'HIGH' AND fi.total_sales > 150000 THEN 'VIP'
    ELSE fi.sales_category
  END AS final_category,
  cg.n AS multiplier,
  fi.total_sales * cg.n AS weighted_sales,
  concat(fi.prefix, '-', CAST(cg.n AS varchar)) AS code
FROM final_items fi
JOIN common_customers cc
  ON EXISTS (
       SELECT 1
       FROM store_sales ss
       WHERE ss.ss_item_sk = fi.i_item_sk
         AND ss.ss_customer_sk = cc.cust_sk
     )
CROSS JOIN cross_grid cg
WHERE fi.i_item_desc LIKE '%AB%'
ORDER BY weighted_sales DESC
LIMIT 100
