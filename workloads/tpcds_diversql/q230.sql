WITH catalog_ret AS (
   SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count,
        'catalog' AS source
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 2001
     AND d.d_holiday = 'N'
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
store_ret AS (
   SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count,
        'store' AS source
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND d.d_holiday = 'N'
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
combined AS (
   SELECT * FROM catalog_ret
   UNION ALL
   SELECT * FROM store_ret
),
small_dim AS (
   SELECT 'Email'   AS channel UNION ALL
   SELECT 'Catalog' AS channel UNION ALL
   SELECT 'TV'      AS channel
)
SELECT
    c.i_item_id,
    c.i_product_name,
    c.source,
    c.total_return_amount,
    c.return_count,
    (SELECT SUM(inv.inv_quantity_on_hand)
       FROM inventory inv
       WHERE inv.inv_item_sk = c.i_item_sk) AS total_inventory_on_hand,
    s.channel
FROM combined c
CROSS JOIN small_dim s
ORDER BY c.total_return_amount DESC
LIMIT 100
