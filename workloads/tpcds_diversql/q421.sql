WITH intersect_items AS (
  SELECT ss.ss_item_sk AS item_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  INTERSECT
  SELECT wr.wr_item_sk
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
)
SELECT
  i.i_item_id,
  i.i_category,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(wr.wr_return_amt) AS total_returns,
  CASE WHEN p.p_promo_sk IS NOT NULL THEN 'Promo' ELSE 'NoPromo' END AS promo_flag
FROM intersect_items ii
JOIN item i ON ii.item_sk = i.i_item_sk
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk AND d_sales.d_year = 2001
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk AND d_ret.d_year = 2001
GROUP BY
  i.i_item_id,
  i.i_category,
  CASE WHEN p.p_promo_sk IS NOT NULL THEN 'Promo' ELSE 'NoPromo' END

UNION

SELECT
  i.i_item_id,
  i.i_category,
  0.0 AS total_sales,
  0.0 AS total_returns,
  'InventoryOnly' AS promo_flag
FROM intersect_items ii
JOIN item i ON ii.item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk AND d_inv.d_year = 2001
GROUP BY i.i_item_id, i.i_category

ORDER BY total_sales DESC
OFFSET 0 ROWS
LIMIT 100
