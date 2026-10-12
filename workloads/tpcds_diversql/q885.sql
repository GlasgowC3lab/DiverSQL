WITH base_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_ext_tax,
    ws.ws_item_sk,
    i.i_brand,
    i.i_category,
    i.i_product_name,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND regexp_like(i.i_product_name, '(?i)toy|game')
    AND c.c_email_address LIKE '%@example.com'
),

set_a AS (
  SELECT ws_order_number
  FROM base_sales
  WHERE ws_ext_sales_price > 200
),

set_b AS (
  SELECT ws_order_number
  FROM base_sales
  WHERE ws_ext_tax > 50
),

intersect_set AS (
  SELECT ws_order_number FROM set_a
  INTERSECT
  SELECT ws_order_number FROM set_b
),

union_set AS (
  SELECT ws_order_number FROM base_sales WHERE i_brand = 'Brand#12'
  UNION
  SELECT ws_order_number FROM base_sales WHERE i_category = 'Sports'
),

final_keys AS (
  SELECT ws_order_number FROM union_set
  EXCEPT
  SELECT ws_order_number FROM intersect_set
)
SELECT
  i_brand,
  i_category,
  SUM(ws_ext_sales_price) AS total_sales,
  AVG(ws_ext_tax) AS avg_tax,
  MIN(CONCAT(c_first_name, ' ', c_last_name)) AS customer_name,
  MIN(SUBSTRING(i_product_name, 1, 10)) AS product_prefix,
  MIN(regexp_extract(i_product_name, '(?i)(Toy|Game)', 1)) AS matched_term
FROM base_sales
JOIN final_keys fk ON base_sales.ws_order_number = fk.ws_order_number
WHERE EXISTS (
  SELECT 1 FROM set_a sa WHERE sa.ws_order_number = base_sales.ws_order_number
)
GROUP BY GROUPING SETS (
  (i_brand, i_category),
  (i_brand),
  ()
)
ORDER BY total_sales DESC
LIMIT 100
