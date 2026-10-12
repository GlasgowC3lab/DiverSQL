WITH
  web_sales_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  anti_store_returns AS (
    SELECT sr_ticket_number
    FROM store_returns
    WHERE sr_return_quantity > 0
  )
SELECT
  s.s_store_name,
  d_year.d_quarter_name,
  i.i_category,
  sm.sm_type,
  flags.flag,
  COUNT(DISTINCT ss.ss_ticket_number)               AS order_cnt,
  SUM(ss.ss_ext_sales_price)                       AS store_sales_amount,
  SUM(ws.ws_ext_sales_price)                       AS web_sales_amount,
  AVG(cr.cr_return_amount)                         AS avg_return_amount,
  MAX(inv.inv_quantity_on_hand)                    AS max_inventory_on_hand,
  SUM(CASE WHEN ws.ws_quantity > 5 THEN 1 ELSE 0 END) AS high_qty_web_orders
FROM store_sales ss
JOIN date_dim d_year
  ON ss.ss_sold_date_sk = d_year.d_date_sk
JOIN time_dim t_time
  ON ss.ss_sold_time_sk = t_time.t_time_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = ss.ss_store_sk  -- dummy join to make ship_mode available early (will be re‑filtered later)
JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = ss.ss_store_sk  -- dummy join to introduce catalog_page early (will be re‑filtered later)
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
 AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
 AND cr.cr_returned_date_sk = d_year.d_date_sk
 AND cr.cr_returned_time_sk = t_time.t_time_sk
JOIN web_sales_sample ws
  ON ws.ws_sold_date_sk = d_year.d_date_sk
 AND ws.ws_sold_time_sk = t_time.t_time_sk
 AND ws.ws_item_sk = i.i_item_sk
 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
 AND ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = ws.ws_item_sk
 AND wr.wr_returned_date_sk = d_year.d_date_sk
 AND wr.wr_returned_time_sk = t_time.t_time_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d_year.d_date_sk
CROSS JOIN (VALUES 1, 2) AS flags(flag)
WHERE d_year.d_year = 2001
  AND i.i_brand_id = 23
  AND s.s_market_id IN (4, 7)
  AND p.p_discount_active = 'Y'
  AND ss.ss_ticket_number NOT IN (SELECT sr_ticket_number FROM anti_store_returns)
GROUP BY
  s.s_store_name,
  d_year.d_quarter_name,
  i.i_category,
  sm.sm_type,
  flags.flag
ORDER BY store_sales_amount DESC
LIMIT 100
