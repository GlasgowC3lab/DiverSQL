WITH inv_wh AS (
   SELECT i.i_item_id AS i_item_id,
          w.w_warehouse_id AS w_warehouse_id,
          inv.inv_quantity_on_hand AS inv_quantity_on_hand
   FROM inventory inv
   FULL OUTER JOIN warehouse w
     ON inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN item i
     ON inv.inv_item_sk = i.i_item_sk
   WHERE inv.inv_quantity_on_hand > 500
),
store_ret AS (
   SELECT
       d.d_date AS return_date,
       'store' AS return_type,
       i.i_item_id AS i_item_id,
       sr.sr_return_quantity AS return_quantity,
       sr.sr_return_amt AS return_amt,
       r.r_reason_desc AS reason_desc
   FROM store_returns sr
   JOIN date_dim d
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i
     ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
     AND s.s_county IN ('Dauphin County', 'Walker County')
     AND EXISTS (
         SELECT 1 FROM inv_wh iw WHERE iw.i_item_id = i.i_item_id
     )
),
web_ret AS (
   SELECT
       d.d_date AS return_date,
       'web' AS return_type,
       i.i_item_id AS i_item_id,
       wr.wr_return_quantity AS return_quantity,
       wr.wr_return_amt AS return_amt,
       r.r_reason_desc AS reason_desc
   FROM web_returns wr
   JOIN date_dim d
     ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i
     ON wr.wr_item_sk = i.i_item_sk
   JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
     AND wp.wp_type = 'article'
     AND EXISTS (
         SELECT 1 FROM inv_wh iw WHERE iw.i_item_id = i.i_item_id
     )
)
SELECT
    return_date,
    return_type,
    i_item_id,
    return_quantity,
    return_amt,
    reason_desc
FROM store_ret
UNION ALL
SELECT
    return_date,
    return_type,
    i_item_id,
    return_quantity,
    return_amt,
    reason_desc
FROM web_ret
ORDER BY return_date DESC, return_type
LIMIT 100
