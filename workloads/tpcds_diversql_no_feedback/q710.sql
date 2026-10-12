WITH
  sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_net_paid,
      d.d_year,
      d.d_date_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 5
  ),
  returns AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_ticket_number,
      sr.sr_return_amt,
      d.d_year AS return_year,
      d.d_date_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  inv AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      d.d_year AS inv_year,
      d.d_date_sk
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND inv.inv_warehouse_sk IN (15, 20)
  ),
  cc AS (
    SELECT
      cc.cc_company_name,
      cc.cc_state,
      d.d_year AS cc_year,
      d.d_date_sk
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
  ),
  ws AS (
    SELECT
      ws.web_site_id,
      ws.web_state,
      d.d_year AS ws_year,
      d.d_date_sk
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.web_state = 'CA'
  ),
  agg AS (
    SELECT
      cc.cc_company_name,
      ws.web_site_id,
      cc.cc_state,
      ws.web_state,
      cc.cc_year,
      SUM(sales.ss_net_paid) AS total_net_paid,
      SUM(returns.sr_return_amt) AS total_return_amt,
      AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand,
      COUNT(DISTINCT sales.ss_ticket_number) AS tickets_sold,
      RANK() OVER (PARTITION BY cc.cc_company_name ORDER BY SUM(sales.ss_net_paid) DESC) AS rnk
    FROM cc
    FULL OUTER JOIN ws ON cc.d_date_sk = ws.d_date_sk
    JOIN sales ON sales.ss_sold_date_sk = cc.d_date_sk
    JOIN returns ON returns.sr_item_sk = sales.ss_item_sk
                 AND returns.sr_ticket_number = sales.ss_ticket_number
    JOIN inv ON inv.inv_item_sk = sales.ss_item_sk
    WHERE EXISTS (
            SELECT 1
            FROM store_returns sr2
            JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
            WHERE sr2.sr_item_sk = sales.ss_item_sk
              AND d2.d_year = 2001
          )
    GROUP BY
      cc.cc_company_name,
      ws.web_site_id,
      cc.cc_state,
      ws.web_state,
      cc.cc_year,
      cc.d_date_sk,
      ws.d_date_sk
    HAVING SUM(sales.ss_net_paid) > 1000
  )
SELECT *
FROM agg
WHERE rnk <= 5
ORDER BY cc_company_name, rnk
