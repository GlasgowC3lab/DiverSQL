SELECT
  brand,
  category,
  total_sales,
  source
FROM (
  SELECT
    i_brand AS brand,
    i_category AS category,
    COALESCE(SUM(ss_ext_sales_price), 0) AS total_sales,
    'store' AS source
  FROM store_sales
  RIGHT OUTER JOIN item ON store_sales.ss_item_sk = item.i_item_sk
  LEFT JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
  WHERE item.i_brand_id IN (2002002, 1002001)
  GROUP BY i_brand, i_category

  UNION ALL

  SELECT
    i_brand AS brand,
    i_category AS category,
    COALESCE(SUM(ws_ext_sales_price), 0) AS total_sales,
    'web' AS source
  FROM web_sales
  RIGHT OUTER JOIN item ON web_sales.ws_item_sk = item.i_item_sk
  LEFT JOIN time_dim ON web_sales.ws_sold_time_sk = time_dim.t_time_sk
  WHERE item.i_brand_id IN (2002002, 1002001)
  GROUP BY i_brand, i_category
) AS combined
ORDER BY brand, category, total_sales DESC
LIMIT 100
