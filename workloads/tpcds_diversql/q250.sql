WITH returned_items AS (
    SELECT i.i_item_id,
           CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Regular' END AS price_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_holiday = 'Y'
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
sold_items AS (
    SELECT i.i_item_id,
           CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Regular' END AS price_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_holiday = 'Y'
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT r.i_item_id,
       r.price_category
FROM returned_items r
EXCEPT
SELECT s.i_item_id,
       s.price_category
FROM sold_items s
LIMIT 100
