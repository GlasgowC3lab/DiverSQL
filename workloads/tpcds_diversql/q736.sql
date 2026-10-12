WITH
  store_items AS (
    SELECT DISTINCT ss_item_sk
    FROM tpcds.store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk IN (
      SELECT d_date_sk
      FROM tpcds.date_dim
      WHERE d_year = 2002
    )
  ),
  web_items AS (
    SELECT DISTINCT ws_item_sk
    FROM tpcds.web_sales
    WHERE ws_sold_date_sk IN (
      SELECT d_date_sk
      FROM tpcds.date_dim
      WHERE d_year = 2002
    )
  ),
  common_items AS (
    SELECT ss_item_sk AS item_sk
    FROM store_items
    INTERSECT
    SELECT ws_item_sk
    FROM web_items
  ),
  small_dates AS (
    SELECT d_date_sk, d_date
    FROM tpcds.date_dim
    WHERE d_year = 2002
    ORDER BY d_date_sk
    LIMIT 5
  )
SELECT
  sd.d_date,
  i.i_item_id,
  ci.item_sk,
  promo
FROM small_dates sd
CROSS JOIN common_items ci
JOIN tpcds.item i
  ON ci.item_sk = i.i_item_sk
CROSS JOIN UNNEST(ARRAY['PROMO_A', 'PROMO_B', 'PROMO_C']) AS t(promo)
LIMIT 100
