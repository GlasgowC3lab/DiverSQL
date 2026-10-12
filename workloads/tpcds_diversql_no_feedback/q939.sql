WITH
  top_items AS (
    SELECT
      ss.ss_store_sk,
      i.i_item_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS item_rank
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_number_employees > 200
    GROUP BY ss.ss_store_sk, i.i_item_id
  ),
  small_dim AS (
    SELECT DISTINCT s.s_market_manager
    FROM store s
    WHERE s.s_market_manager IS NOT NULL
    LIMIT 5
  ),
  intersect_items AS (
    SELECT i.i_item_id
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INTERSECT
    SELECT i.i_item_id
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
  )
SELECT
  dm.s_market_manager,
  ti.ss_store_sk,
  ti.i_item_id,
  ti.total_sales,
  ti.item_rank,
  ii.i_item_id AS common_item_id
FROM small_dim dm
CROSS JOIN top_items ti
LEFT JOIN intersect_items ii ON ti.i_item_id = ii.i_item_id
LIMIT 100
