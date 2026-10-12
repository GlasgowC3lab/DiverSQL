WITH sales_sub AS (
  SELECT ss.ss_ticket_number,
         ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_net_paid AS sales_amount,
         d.d_date,
         d.d_year,
         i.i_item_id,
         s.s_store_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
),
returns_sub AS (
  SELECT sr.sr_ticket_number,
         sr.sr_returned_date_sk,
         sr.sr_item_sk,
         sr.sr_return_amt AS return_amount,
         d.d_date,
         d.d_year,
         i.i_item_id,
         st.s_store_name
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store st ON sr.sr_store_sk = st.s_store_sk
  WHERE d.d_year = 2001
),
full_join_2001 AS (
  SELECT
    COALESCE(ss.d_date, rr.d_date) AS trans_date,
    COALESCE(ss.i_item_id, rr.i_item_id) AS item_id,
    ss.s_store_name AS sale_store,
    rr.s_store_name AS return_store,
    ss.sales_amount,
    rr.return_amount,
    ss.ss_item_sk,
    ss.ss_sold_date_sk
  FROM (
    SELECT ss_ticket_number,
           ss_sold_date_sk,
           ss_item_sk,
           sales_amount,
           d_date,
           i_item_id,
           s_store_name
    FROM sales_sub
  ) ss
  FULL OUTER JOIN (
    SELECT sr_ticket_number,
           sr_returned_date_sk,
           sr_item_sk,
           return_amount,
           d_date,
           i_item_id,
           s_store_name
    FROM returns_sub
  ) rr
    ON ss.ss_ticket_number = rr.sr_ticket_number
   AND ss.i_item_id = rr.i_item_id
),
filtered_2001 AS (
  SELECT *
  FROM full_join_2001 fj
  WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = fj.ss_item_sk
      AND cr.cr_returned_date_sk = fj.ss_sold_date_sk
  )
),
-- second year (2000) -----------------------------------------------------------------
sales_sub_2000 AS (
  SELECT ss.ss_ticket_number,
         ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_net_paid AS sales_amount,
         d.d_date,
         i.i_item_id,
         s.s_store_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2000
),
returns_sub_2000 AS (
  SELECT sr.sr_ticket_number,
         sr.sr_returned_date_sk,
         sr.sr_item_sk,
         sr.sr_return_amt AS return_amount,
         d.d_date,
         i.i_item_id,
         st.s_store_name
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store st ON sr.sr_store_sk = st.s_store_sk
  WHERE d.d_year = 2000
),
full_join_2000 AS (
  SELECT
    COALESCE(ss.d_date, rr.d_date) AS trans_date,
    COALESCE(ss.i_item_id, rr.i_item_id) AS item_id,
    ss.s_store_name AS sale_store,
    rr.s_store_name AS return_store,
    ss.sales_amount,
    rr.return_amount,
    ss.ss_item_sk,
    ss.ss_sold_date_sk
  FROM (
    SELECT ss_ticket_number,
           ss_sold_date_sk,
           ss_item_sk,
           sales_amount,
           d_date,
           i_item_id,
           s_store_name
    FROM sales_sub_2000
  ) ss
  FULL OUTER JOIN (
    SELECT sr_ticket_number,
           sr_returned_date_sk,
           sr_item_sk,
           return_amount,
           d_date,
           i_item_id,
           s_store_name
    FROM returns_sub_2000
  ) rr
    ON ss.ss_ticket_number = rr.sr_ticket_number
   AND ss.i_item_id = rr.i_item_id
),
filtered_2000 AS (
  SELECT *
  FROM full_join_2000 fj
  WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = fj.ss_item_sk
      AND cr.cr_returned_date_sk = fj.ss_sold_date_sk
  )
)
SELECT trans_date,
       item_id,
       sale_store,
       return_store,
       sales_amount,
       return_amount
FROM filtered_2001
UNION ALL
SELECT trans_date,
       item_id,
       sale_store,
       return_store,
       sales_amount,
       return_amount
FROM filtered_2000
ORDER BY trans_date DESC
LIMIT 100
