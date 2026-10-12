WITH
  ws AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk AS d_date_sk,
      ws.ws_web_site_sk,
      ws.ws_sales_price,
      ws.ws_quantity,
      ws.ws_net_profit,
      ws.ws_item_sk,
      ws.ws_web_page_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(CAST(ws.ws_order_number AS VARCHAR), '^1[0-9]{5}$')
  ),
  sr AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk AS d_date_sk,
      sr.sr_item_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_store_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_quantity > 0
  ),
  ws_sr_full AS (
    SELECT
      COALESCE(ws.d_date_sk, sr.d_date_sk) AS d_date_sk,
      ws.ws_order_number,
      ws.ws_sales_price,
      ws.ws_quantity,
      ws.ws_net_profit,
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_return_quantity
    FROM ws
    FULL OUTER JOIN sr ON ws.d_date_sk = sr.d_date_sk
  ),
  order_without_return AS (
    SELECT ws_order_number FROM ws
    EXCEPT
    SELECT wr.wr_order_number FROM web_returns wr
  )
SELECT
  fs.d_date_sk,
  CASE
    WHEN fs.ws_sales_price IS NULL THEN 'No Sale'
    WHEN fs.sr_return_amt IS NULL THEN 'No Return'
    ELSE 'Sale & Return'
  END AS activity_type,
  COALESCE(fs.ws_sales_price, 0) - COALESCE(fs.sr_return_amt, 0) AS net_amount,
  (
    SELECT COUNT(*)
    FROM web_sales ws2
    WHERE ws2.ws_order_number = fs.ws_order_number
  ) AS sales_count_per_order,
  CONCAT('ORD-', CAST(fs.ws_order_number AS VARCHAR)) AS order_label,
  SUBSTRING(CAST(fs.ws_order_number AS VARCHAR) FROM 1 FOR 3) AS order_prefix,
  REGEXP_EXTRACT(CAST(fs.ws_order_number AS VARCHAR), '(\\d{2})(\\d{3})', 2) AS order_suffix
FROM ws_sr_full fs
WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_order_number = fs.ws_order_number
      )
  AND fs.d_date_sk IS NOT NULL
ORDER BY fs.d_date_sk DESC, net_amount DESC
LIMIT 100
