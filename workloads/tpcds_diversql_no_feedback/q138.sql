WITH damaged_return_items AS (
  SELECT DISTINCT cr.cr_item_sk
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE LOWER(r.r_reason_desc) LIKE '%damaged%'
),
sold_items AS (
  SELECT DISTINCT ss.ss_item_sk
  FROM store_sales ss
),
eligible_items AS (
  SELECT ss_item_sk
  FROM sold_items
  EXCEPT
  SELECT cr_item_sk
  FROM damaged_return_items
),
joined_data AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_city AS city,
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_transactions,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_profit) DESC) AS rnk
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN eligible_items ei ON ss.ss_item_sk = ei.ss_item_sk
  WHERE REGEXP_LIKE(i.i_product_name, '(Pro|Deluxe)')
    AND i.i_product_name LIKE '%Red%'
    AND SUBSTRING(s.s_city, 1, 1) = 'U'
  GROUP BY s.s_store_id, s.s_city, i.i_item_id, i.i_product_name
  HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
  store_id,
  city,
  item_id,
  product_name,
  total_net_profit,
  sales_transactions,
  rnk
FROM joined_data
WHERE rnk <= 3
ORDER BY total_net_profit DESC
LIMIT 100
