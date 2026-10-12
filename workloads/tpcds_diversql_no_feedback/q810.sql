WITH cat_returns AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_date AS return_date,
    cr.cr_return_amount,
    CAST('catalog' AS varchar) AS source
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND cr.cr_return_amount > 0
),
web_returns AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_date AS return_date,
    wr.wr_return_amt AS return_amount,
    CAST('web' AS varchar) AS source
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND wr.wr_return_amt > 0
),
combined AS (
  SELECT i_item_id, i_product_name, return_date, cr_return_amount AS return_amount, source FROM cat_returns
  UNION ALL
  SELECT i_item_id, i_product_name, return_date, return_amount, source FROM web_returns
)
SELECT
  i_item_id,
  i_product_name,
  return_date,
  return_amount,
  source,
  SUM(return_amount) OVER (
    PARTITION BY i_item_id
    ORDER BY return_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cum_return_amount
FROM combined
ORDER BY cum_return_amount DESC
LIMIT 100
