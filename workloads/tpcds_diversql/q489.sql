WITH filtered_sales AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_catalog_page_sk,
    cs.cs_bill_customer_sk,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    i.i_item_desc,
    cp.cp_department,
    cp.cp_description
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE cp.cp_description LIKE '%Special%'
    AND regexp_like(i.i_item_desc, '(TV|Camera)')
)
SELECT
  fs.cp_department,
  COUNT(DISTINCT fs.c_customer_sk) AS distinct_customers,
  SUM(fs.cs_ext_sales_price) AS total_sales,
  CASE
    WHEN SUM(fs.cs_quantity) > 1000 THEN 'HIGH_VOLUME'
    ELSE 'NORMAL_VOLUME'
  END AS volume_category,
  (
    SELECT AVG(cr.cr_return_amount)
    FROM catalog_returns cr
    JOIN catalog_page cp2
      ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    WHERE cp2.cp_department = fs.cp_department
  ) AS avg_return_amount,
  regexp_extract(MAX(fs.i_item_desc), '^([^ ]+)', 1) AS first_word_item_desc,
  CONCAT(MAX(fs.c_first_name), ' ', MAX(fs.c_last_name)) AS sample_customer_name
FROM filtered_sales fs
WHERE NOT EXISTS (
  SELECT 1
  FROM web_sales ws
  WHERE ws.ws_item_sk = fs.cs_item_sk
    AND ws.ws_sold_date_sk = fs.cs_sold_date_sk
)
GROUP BY fs.cp_department
ORDER BY total_sales DESC
LIMIT 100
