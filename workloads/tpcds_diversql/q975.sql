WITH
    store_items AS (
        SELECT DISTINCT sr.sr_item_sk
        FROM tpcds.store_returns sr
        TABLESAMPLE BERNOULLI (10)
        JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
    ),
    catalog_items AS (
        SELECT DISTINCT cr.cr_item_sk
        FROM tpcds.catalog_returns cr
        JOIN tpcds.date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2002
          AND cr.cr_return_amount > 0
    ),
    common_items AS (
        SELECT sr_item_sk AS item_sk FROM store_items
        INTERSECT
        SELECT cr_item_sk AS item_sk FROM catalog_items
    )
SELECT
    i.i_item_id,
    i.i_category,
    i.i_item_desc,
    MIN(regexp_extract(i.i_item_desc, '(\\w+)', 1)) AS sample_word,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_quantity,
    CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_level
FROM tpcds.store_returns sr
JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.date_dim d3 ON sr.sr_returned_date_sk = d3.d_date_sk
JOIN common_items ci ON sr.sr_item_sk = ci.item_sk
WHERE d3.d_year = 2002
  AND REGEXP_LIKE(i.i_item_desc, '(?i)coffee|tea')
  AND r.r_reason_desc LIKE '%Damaged%'
GROUP BY i.i_item_id, i.i_category, i.i_item_desc
HAVING SUM(sr.sr_net_loss) > 500
ORDER BY total_net_loss DESC
LIMIT 100
