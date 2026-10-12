WITH
  sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
  ),
  intersect_tickets AS (
    SELECT ss_ticket_number FROM sampled_sales
    INTERSECT
    SELECT sr_ticket_number FROM store_returns
  ),
  base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_list_price,
      ca1.ca_city                     AS sales_city,
      r.sr_return_amt,
      r.sr_return_quantity,
      cs.cs_ext_sales_price,
      cc.cc_name,
      ca2.ca_state                    AS ship_state,
      ROW_NUMBER() OVER (ORDER BY ss.ss_ticket_number) AS rn
    FROM sampled_sales ss
    JOIN customer_address ca1
      ON ss.ss_addr_sk = ca1.ca_address_sk
    JOIN store_returns r
      ON r.sr_item_sk = ss.ss_item_sk
    JOIN customer_address ca2
      ON r.sr_addr_sk = ca2.ca_address_sk
    JOIN catalog_sales cs
      ON cs.cs_bill_addr_sk = ca1.ca_address_sk
    JOIN catalog_sales cs_ship
      ON cs_ship.cs_ship_addr_sk = ca2.ca_address_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN store_sales ss_dup
      ON ss_dup.ss_ticket_number = r.sr_ticket_number
    JOIN catalog_sales cs2
      ON cs2.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca3
      ON ss_dup.ss_addr_sk = ca3.ca_address_sk
    WHERE ss.ss_quantity > 0
      AND ss.ss_ticket_number IN (SELECT ss_ticket_number FROM intersect_tickets)
  ),
  unioned AS (
    SELECT
      b.ss_ticket_number,
      b.ss_quantity,
      b.ss_list_price,
      b.sales_city,
      b.sr_return_amt,
      b.sr_return_quantity,
      b.cs_ext_sales_price,
      b.cc_name,
      b.ship_state,
      b.rn
    FROM base b
    UNION DISTINCT
    SELECT
      b.ss_ticket_number,
      b.ss_quantity,
      b.ss_list_price,
      b.sales_city,
      b.sr_return_amt,
      b.sr_return_quantity,
      b.cs_ext_sales_price,
      b.cc_name,
      b.ship_state,
      b.rn
    FROM base b
    WHERE b.ss_quantity >= 30
  )
SELECT
  u.cc_name,
  u.sales_city,
  COUNT(DISTINCT u.ss_ticket_number) AS tickets_sold,
  SUM(u.ss_quantity)               AS total_quantity,
  AVG(u.ss_list_price)            AS avg_list_price,
  SUM(u.sr_return_amt)            AS total_return_amount,
  MAX(u.rn)                       AS max_row_number
FROM unioned u
CROSS JOIN (VALUES (1), (2), (3)) AS t(offset)   -- small computed set
GROUP BY u.cc_name, u.sales_city
HAVING COUNT(DISTINCT u.ss_ticket_number) > 5
ORDER BY total_quantity DESC
LIMIT 100
