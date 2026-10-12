WITH
  store_items AS (
    SELECT d.d_year AS year,
           i.i_item_id AS item_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_brand = 'Brand#12'
  ),
  web_items AS (
    SELECT d.d_year AS year,
           i.i_item_id AS item_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_brand = 'Brand#12'
  ),
  catalog_items AS (
    SELECT d.d_year AS year,
           i.i_item_id AS item_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_brand = 'Brand#12'
  ),
  union_items AS (
    SELECT year, item_id FROM store_items
    UNION
    SELECT year, item_id FROM web_items
  )
SELECT year, item_id
FROM union_items
INTERSECT
SELECT year, item_id FROM catalog_items
ORDER BY year, item_id
