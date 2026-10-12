SELECT
    i.i_item_id,
    i.i_brand,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(cr.cr_net_loss) AS total_net_loss,
    (SELECT i2.i_product_name
     FROM item i2
     WHERE i2.i_category = 'Books                                             '
     LIMIT 1) AS product_name_sub
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
WHERE cr.cr_returned_date_sk = 2450959
  AND i.i_brand = 'namelessbrand #1                                  '
GROUP BY i.i_item_id, i.i_brand
HAVING SUM(ss.ss_net_paid) > 3655.52
