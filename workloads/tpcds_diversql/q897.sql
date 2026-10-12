WITH
  sales_dim AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      d.d_year,
      i.i_item_id,
      i.i_category_id,
      s.s_store_name,
      CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM store_sales ss
    RIGHT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_category_id IN (3, 4, 7, 9, 10)
      AND s.s_state = 'CA'
      AND ss.ss_quantity > 0
  ),
  returns_dim AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_store_sk,
      sr.sr_ticket_number,
      sr.sr_return_quantity,
      r.r_reason_desc,
      d.d_year
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE r.r_reason_desc NOT LIKE '%size%'
  ),
  catalog_ret AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_item_sk,
      cr.cr_return_amount,
      r.r_reason_desc,
      d.d_year
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_return_amount > 100
  ),
  web_sales_dim AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      d.d_year,
      i.i_item_id
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity > 0
  ),
  union_items AS (
    SELECT DISTINCT i.i_item_id, i.i_category_id FROM item i WHERE i.i_category_id IN (3, 4)
    UNION
    SELECT DISTINCT CAST(cr.cr_item_sk AS VARCHAR), NULL FROM catalog_returns cr WHERE cr.cr_return_amount > 0
  ),
  distinct_item_counts AS (
    SELECT
      COUNT(DISTINCT ss.ss_item_sk) AS distinct_sold_items,
      COUNT(DISTINCT sr.sr_item_sk) AS distinct_returned_items
    FROM store_sales ss
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  ),
  item_not_returned AS (
    SELECT ss_item_sk FROM store_sales
    EXCEPT
    SELECT sr_item_sk FROM store_returns
  )
SELECT
  sd.d_year,
  sd.s_store_name,
  sd.i_item_id,
  sd.i_category_id,
  sd.profit_flag,
  sd.ss_quantity,
  sd.ss_net_paid,
  rd.r_reason_desc,
  cr.r_reason_desc AS catalog_reason,
  ws.ws_quantity,
  ws.ws_net_paid,
  uc.i_item_id AS union_item_id,
  uc.i_category_id AS union_category_id,
  dic.distinct_sold_items,
  dic.distinct_returned_items,
  ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.ss_net_paid DESC) AS sales_rownum,
  RANK() OVER (PARTITION BY sd.d_year ORDER BY sd.ss_net_profit DESC) AS profit_rank
FROM sales_dim sd
LEFT JOIN returns_dim rd ON sd.ss_ticket_number = rd.sr_ticket_number AND sd.ss_item_sk = rd.sr_item_sk
FULL OUTER JOIN catalog_ret cr ON sd.ss_item_sk = cr.cr_item_sk AND sd.d_year = cr.d_year
FULL OUTER JOIN web_sales_dim ws ON sd.ss_item_sk = ws.ws_item_sk AND sd.d_year = ws.d_year
LEFT JOIN union_items uc ON sd.i_item_id = uc.i_item_id
CROSS JOIN distinct_item_counts dic
WHERE sd.profit_flag = 'POS'
  AND (rd.r_reason_desc IS NOT NULL OR cr.r_reason_desc IS NOT NULL)
  AND sd.ss_net_paid > 1000
  AND uc.i_category_id IS NOT NULL
ORDER BY sd.d_year DESC, profit_rank ASC
LIMIT 100
