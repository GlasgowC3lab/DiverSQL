WITH
  recent_sales AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      i.i_category,
      i.i_brand,
      i.i_item_desc,
      d.d_year
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),
  store_ret AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      i.i_category,
      i.i_brand,
      i.i_item_desc,
      d.d_year
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),
  filtered_sales AS (
    SELECT *
    FROM recent_sales rs
    WHERE rs.cs_item_sk NOT IN (
      SELECT inv.inv_item_sk
      FROM inventory inv
      WHERE inv.inv_quantity_on_hand = 0
    )
  ),
  expanded_desc AS (
    SELECT
      rs.cs_item_sk,
      rs.i_category,
      rs.i_brand,
      word
    FROM filtered_sales rs
    CROSS JOIN UNNEST(split(rs.i_item_desc, ' ')) AS t(word)
  ),
  intersect_items AS (
    SELECT cs_item_sk AS item_sk
    FROM expanded_desc
    WHERE lower(word) = 'brand'
    INTERSECT
    SELECT sr_item_sk AS item_sk
    FROM store_ret
    WHERE i_brand = 'brandbrand #4'
  )
SELECT
  i.i_category,
  i.i_brand,
  COUNT(*) AS cnt
FROM intersect_items ii
JOIN item i ON ii.item_sk = i.i_item_sk
GROUP BY CUBE(i.i_category, i.i_brand)
ORDER BY cnt DESC
LIMIT 100
