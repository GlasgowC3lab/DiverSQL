WITH cr_data AS (
   SELECT
       w1.w_warehouse_name AS warehouse_name,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       r1.r_reason_desc AS reason_desc
   FROM catalog_returns cr
   JOIN warehouse w1 ON cr.cr_warehouse_sk = w1.w_warehouse_sk
   JOIN reason r1 ON cr.cr_reason_sk = r1.r_reason_sk
   FULL OUTER JOIN warehouse w2 ON cr.cr_warehouse_sk = w2.w_warehouse_sk
   JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
   JOIN warehouse w3 ON cr.cr_warehouse_sk = w3.w_warehouse_sk
   FULL OUTER JOIN warehouse w4 ON cr.cr_warehouse_sk = w4.w_warehouse_sk
   JOIN warehouse w5 ON cr.cr_warehouse_sk = w5.w_warehouse_sk
   FULL OUTER JOIN warehouse w6 ON cr.cr_warehouse_sk = w6.w_warehouse_sk
),
sr_data AS (
   SELECT
       sr.sr_return_quantity,
       sr.sr_return_amt,
       r3.r_reason_desc AS reason_desc
   FROM store_returns sr
   JOIN reason r3 ON sr.sr_reason_sk = r3.r_reason_sk
   JOIN reason r4 ON sr.sr_reason_sk = r4.r_reason_sk
),
ws_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_ext_sales_price,
       ws.ws_quantity,
       w7.w_warehouse_name AS warehouse_name
   FROM web_sales ws
   JOIN warehouse w7 ON ws.ws_warehouse_sk = w7.w_warehouse_sk
   FULL OUTER JOIN warehouse w8 ON ws.ws_warehouse_sk = w8.w_warehouse_sk
),
agg_a AS (
   SELECT
       warehouse_name,
       SUM(cr_return_amount)        AS total_return_amount,
       SUM(cr_return_quantity)      AS total_return_qty,
       COUNT(DISTINCT word)         AS distinct_word_cnt
   FROM (
       SELECT
           warehouse_name,
           cr_return_amount,
           cr_return_quantity,
           word
       FROM cr_data
       CROSS JOIN UNNEST(split(reason_desc, ' ')) AS t(word)
   )
   GROUP BY warehouse_name
   HAVING SUM(cr_return_amount) > 0
),
agg_b AS (
   SELECT
       warehouse_name,
       SUM(ws_ext_sales_price) AS total_return_amount,
       SUM(ws_quantity)        AS total_return_qty,
       COUNT(DISTINCT word)    AS distinct_word_cnt
   FROM (
       SELECT
           warehouse_name,
           ws_ext_sales_price,
           ws_quantity,
           word
       FROM ws_data
       CROSS JOIN UNNEST(split(warehouse_name, ' ')) AS t(word)
   )
   GROUP BY warehouse_name
   HAVING SUM(ws_ext_sales_price) > 0
)
SELECT *
FROM agg_a
EXCEPT
SELECT *
FROM agg_b
ORDER BY total_return_amount DESC
LIMIT 100
