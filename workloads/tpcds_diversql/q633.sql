WITH
  sales_by_item AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
    FROM catalog_sales cs
    RIGHT OUTER JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
  ),
  returns_by_item AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
  ),
  full_store_returns AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      SUM(sr.sr_return_amt) AS total_store_return
    FROM store s
    FULL OUTER JOIN store_returns sr
      ON s.s_store_sk = sr.sr_store_sk
    GROUP BY s.s_store_id, s.s_store_name
  ),
  items_in_both_sales_and_store_returns AS (
    SELECT cs.cs_item_sk AS i_item_sk
    FROM catalog_sales cs
    INTERSECT
    SELECT sr.sr_item_sk
    FROM store_returns sr
  ),
  items_sold_not_returned AS (
    SELECT cs.cs_item_sk AS i_item_sk
    FROM catalog_sales cs
    EXCEPT
    SELECT cr.cr_item_sk
    FROM catalog_returns cr
  ),
  high_refund_customers AS (
    SELECT c.c_customer_id, c.c_email_address
    FROM customer c
    WHERE c.c_customer_sk IN (
      SELECT cr.cr_refunded_customer_sk
      FROM catalog_returns cr
      WHERE cr.cr_return_amount > 1000
    )
  )
SELECT
  sb.i_item_id AS entity_id,
  'Item' AS entity_type,
  sb.total_sales,
  COALESCE(rb.total_returns, 0) AS total_returns,
  sb.volume_category
FROM sales_by_item sb
LEFT JOIN returns_by_item rb
  ON sb.i_item_sk = rb.i_item_sk
WHERE sb.i_item_sk IN (SELECT i_item_sk FROM items_in_both_sales_and_store_returns)

UNION ALL

SELECT
  fsr.s_store_id AS entity_id,
  'Store' AS entity_type,
  NULL AS total_sales,
  fsr.total_store_return AS total_returns,
  NULL AS volume_category
FROM full_store_returns fsr
JOIN store s
  ON s.s_store_id = fsr.s_store_id
WHERE s.s_store_id IS NOT NULL

ORDER BY total_sales DESC NULLS LAST
LIMIT 100
