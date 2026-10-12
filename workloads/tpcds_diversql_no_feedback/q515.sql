WITH
  returns_agg AS (
    SELECT
      d.d_day_name AS day_name,
      i.i_class AS item_class,
      SUM(cr.cr_return_amount) AS total_amount,
      COUNT(*) AS cnt,
      'returns' AS src
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_class IN ('pop', 'decor')
      AND NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = cr.cr_returned_date_sk
          AND inv.inv_item_sk = cr.cr_item_sk
      )
    GROUP BY ROLLUP (d.d_day_name, i.i_class)
  ),
  sales_agg AS (
    SELECT
      d.d_day_name AS day_name,
      i.i_class AS item_class,
      SUM(ws.ws_ext_sales_price) AS total_amount,
      COUNT(*) AS cnt,
      'sales' AS src
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_class IN ('pop', 'decor')
      AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_returned_date_sk = ws.ws_sold_date_sk
          AND cr.cr_item_sk = ws.ws_item_sk
      )
    GROUP BY ROLLUP (d.d_day_name, i.i_class)
  )
SELECT
  day_name,
  item_class,
  total_amount,
  cnt,
  src
FROM returns_agg
UNION ALL
SELECT
  day_name,
  item_class,
  total_amount,
  cnt,
  src
FROM sales_agg
ORDER BY src, day_name NULLS LAST, item_class NULLS LAST
LIMIT 100
