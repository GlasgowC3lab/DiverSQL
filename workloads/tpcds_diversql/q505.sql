WITH
  high_price_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 100
  ),
  active_promos AS (
    SELECT p_item_sk AS i_item_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
  ),
  intersect_items AS (
    SELECT i_item_sk
    FROM high_price_items
    INTERSECT
    SELECT i_item_sk
    FROM active_promos
  ),
  sales_recent AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      d.d_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2001
          )
      AND ss.ss_item_sk IN (SELECT i_item_sk FROM high_price_items)
      AND ss.ss_quantity > (
            SELECT AVG(ss2.ss_quantity)
            FROM store_sales ss2
            WHERE ss2.ss_sold_date_sk = ss.ss_sold_date_sk
          )
  ),
  returns_recent AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_item_sk,
      sr.sr_returned_date_sk,
      sr.sr_return_quantity,
      sr.sr_refunded_cash,
      d.d_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_item_sk IN (SELECT i_item_sk FROM intersect_items)
      AND sr.sr_return_quantity > (
            SELECT MIN(sr2.sr_return_quantity)
            FROM store_returns sr2
            WHERE sr2.sr_returned_date_sk = sr.sr_returned_date_sk
          )
  )
SELECT
  ss_ticket_number        AS ticket_number,
  ss_item_sk              AS item_sk,
  ss_sold_date_sk         AS date_sk,
  ss_quantity             AS quantity,
  ss_net_paid             AS amount,
  d_year                  AS year,
  'sale'                  AS source_type
FROM sales_recent
UNION ALL
SELECT
  sr_ticket_number        AS ticket_number,
  sr_item_sk              AS item_sk,
  sr_returned_date_sk     AS date_sk,
  sr_return_quantity      AS quantity,
  sr_refunded_cash        AS amount,
  d_year                  AS year,
  'return'                AS source_type
FROM returns_recent
ORDER BY year DESC, amount DESC
LIMIT 100
