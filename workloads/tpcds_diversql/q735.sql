WITH
  filtered_items AS (
    SELECT i_item_sk,
           i_current_price,
           i_category
    FROM   item
    WHERE  i_current_price > (
             SELECT avg(i_current_price)
             FROM   item
           )
  ),
  catalog_agg AS (
    SELECT cr_reason_sk,
           SUM(cr_return_amount)                     AS total_return_amount,
           COUNT(*)                                 AS return_cnt,
           CASE WHEN SUM(cr_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM   catalog_returns
    WHERE  cr_item_sk IN (SELECT i_item_sk FROM filtered_items)
    GROUP BY cr_reason_sk
  ),
  web_agg AS (
    SELECT wr_reason_sk,
           SUM(wr_return_amt)                      AS total_return_amount,
           COUNT(*)                                AS return_cnt,
           CASE WHEN SUM(wr_return_amt) > 10000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM   web_returns
    WHERE  wr_item_sk IN (SELECT i_item_sk FROM filtered_items)
    GROUP BY wr_reason_sk
  ),
  full_join AS (
    SELECT COALESCE(c.cr_reason_sk, w.wr_reason_sk)                AS reason_sk,
           c.total_return_amount                                   AS catalog_return_amount,
           w.total_return_amount                                   AS web_return_amount,
           c.amount_category                                      AS catalog_category,
           w.amount_category                                      AS web_category
    FROM   catalog_agg c
    FULL OUTER JOIN web_agg w
      ON c.cr_reason_sk = w.wr_reason_sk
  )
SELECT f.reason_sk,
       COALESCE(r.r_reason_desc, 'Unknown')                           AS reason_desc,
       f.catalog_return_amount,
       f.web_return_amount,
       CASE
         WHEN f.catalog_return_amount IS NULL THEN 'WEB ONLY'
         WHEN f.web_return_amount IS NULL THEN 'CATALOG ONLY'
         ELSE 'BOTH'
       END                                                            AS source_type
FROM   full_join f
LEFT JOIN reason r
  ON f.reason_sk = r.r_reason_sk
WHERE  f.reason_sk IN (
         SELECT r2.r_reason_sk
         FROM   reason r2
         WHERE  r2.r_reason_id LIKE 'AAAA%'
       )
ORDER BY f.reason_sk
LIMIT 100
