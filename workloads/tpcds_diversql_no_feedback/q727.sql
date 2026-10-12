WITH
  store_agg AS (
    SELECT
      d.d_year AS year,
      i.i_item_id AS item_id,
      i.i_product_name AS product_name,
      SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_year, i.i_item_id, i.i_product_name
  ),
  store_top AS (
    SELECT
      year,
      item_id,
      product_name,
      total_sales,
      ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_sales DESC) AS rank_num,
      'store' AS sales_channel
    FROM store_agg
  ),
  web_agg AS (
    SELECT
      d.d_year AS year,
      i.i_item_id AS item_id,
      i.i_product_name AS product_name,
      SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_year, i.i_item_id, i.i_product_name
  ),
  web_top AS (
    SELECT
      year,
      item_id,
      product_name,
      total_sales,
      ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_sales DESC) AS rank_num,
      'web' AS sales_channel
    FROM web_agg
  ),
  combined AS (
    SELECT year, item_id, product_name, total_sales, rank_num, sales_channel
    FROM store_top
    WHERE rank_num <= 5
    UNION ALL
    SELECT year, item_id, product_name, total_sales, rank_num, sales_channel
    FROM web_top
    WHERE rank_num <= 5
  )
SELECT
  year,
  item_id,
  product_name,
  total_sales,
  sales_channel,
  rank_num
FROM combined
ORDER BY year, sales_channel, rank_num
LIMIT 100
