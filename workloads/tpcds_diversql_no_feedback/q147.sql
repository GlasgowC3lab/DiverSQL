WITH sales AS (
  SELECT
    i.i_item_id AS item_id,
    i.i_item_desc AS item_desc,
    'sales' AS src,
    SUM(ws.ws_ext_sales_price) AS total_amount,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS amount_category
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_id, i.i_item_desc
),
returns AS (
  SELECT
    i.i_item_id AS item_id,
    i.i_item_desc AS item_desc,
    'returns' AS src,
    SUM(cr.cr_return_amount) AS total_amount,
    CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS amount_category
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_id, i.i_item_desc
),
combined AS (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
)
SELECT
  ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS row_num,
  item_id,
  item_desc,
  src,
  total_amount,
  amount_category
FROM combined
ORDER BY row_num
LIMIT 100
