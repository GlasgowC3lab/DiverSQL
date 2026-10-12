WITH unified AS (
  SELECT d.d_date,
         i.i_category,
         'store' AS channel,
         'sale' AS trx_type,
         ss.ss_ext_sales_price AS sales_amount,
         CAST(0 AS decimal(7,2)) AS return_amount,
         CAST(0 AS decimal(7,2)) AS net_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk

  UNION ALL

  SELECT d.d_date,
         i.i_category,
         'store' AS channel,
         'return' AS trx_type,
         CAST(0 AS decimal(7,2)) AS sales_amount,
         sr.sr_return_amt AS return_amount,
         sr.sr_net_loss AS net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk

  UNION ALL

  SELECT d.d_date,
         i.i_category,
         'web' AS channel,
         'sale' AS trx_type,
         ws.ws_ext_sales_price AS sales_amount,
         CAST(0 AS decimal(7,2)) AS return_amount,
         CAST(0 AS decimal(7,2)) AS net_loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk

  UNION ALL

  SELECT d.d_date,
         i.i_category,
         'web' AS channel,
         'return' AS trx_type,
         CAST(0 AS decimal(7,2)) AS sales_amount,
         wr.wr_return_amt AS return_amount,
         wr.wr_net_loss AS net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk

  UNION ALL

  SELECT d.d_date,
         i.i_category,
         'catalog' AS channel,
         'sale' AS trx_type,
         cs.cs_ext_sales_price AS sales_amount,
         CAST(0 AS decimal(7,2)) AS return_amount,
         CAST(0 AS decimal(7,2)) AS net_loss
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk

  UNION ALL

  SELECT d.d_date,
         i.i_category,
         'catalog' AS channel,
         'return' AS trx_type,
         CAST(0 AS decimal(7,2)) AS sales_amount,
         cr.cr_return_amount AS return_amount,
         cr.cr_net_loss AS net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
agg AS (
  SELECT
    d_date,
    i_category,
    sum(CASE WHEN channel = 'store' AND trx_type = 'sale' THEN sales_amount ELSE 0 END) AS store_sales_amount,
    sum(CASE WHEN channel = 'web' AND trx_type = 'sale' THEN sales_amount ELSE 0 END) AS web_sales_amount,
    sum(CASE WHEN channel = 'catalog' AND trx_type = 'sale' THEN sales_amount ELSE 0 END) AS catalog_sales_amount,
    sum(sales_amount) AS total_sales_amount,
    sum(CASE WHEN channel = 'store' AND trx_type = 'return' THEN return_amount ELSE 0 END) AS store_return_amount,
    sum(CASE WHEN channel = 'web' AND trx_type = 'return' THEN return_amount ELSE 0 END) AS web_return_amount,
    sum(CASE WHEN channel = 'catalog' AND trx_type = 'return' THEN return_amount ELSE 0 END) AS catalog_return_amount,
    sum(CASE WHEN trx_type = 'return' THEN return_amount ELSE 0 END) AS total_return_amount,
    sum(CASE WHEN trx_type = 'return' THEN net_loss ELSE 0 END) AS total_return_loss
  FROM unified
  WHERE d_date >= DATE '2000-01-01' AND d_date < DATE '2001-01-01'
  GROUP BY d_date, i_category
)
SELECT
  d_date,
  i_category,
  store_sales_amount,
  web_sales_amount,
  catalog_sales_amount,
  total_sales_amount,
  store_return_amount,
  web_return_amount,
  catalog_return_amount,
  total_return_amount,
  total_sales_amount - total_return_amount AS net_revenue,
  ROUND((total_sales_amount - total_return_amount) / NULLIF(total_sales_amount, 0) * 100, 2) AS net_margin_pct,
  SUM(total_sales_amount) OVER (PARTITION BY i_category ORDER BY d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS sales_3day_moving_sum,
  RANK() OVER (PARTITION BY year(d_date), month(d_date) ORDER BY (total_sales_amount - total_return_amount) DESC) AS month_category_rank
FROM agg
ORDER BY net_revenue DESC
LIMIT 100
