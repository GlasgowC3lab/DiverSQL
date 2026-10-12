WITH
  store_sales_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_sold_time_sk,
      ss_store_sk,
      ss_item_sk,
      ss_ticket_number,
      ss_net_paid,
      ss_quantity
    FROM store_sales
  ),
  catalog_sales_agg AS (
    SELECT
      cs_sold_date_sk,
      cs_item_sk,
      cs_net_paid,
      cs_quantity
    FROM catalog_sales
  ),
  web_sales_agg AS (
    SELECT
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_item_sk,
      ws_web_page_sk,
      ws_web_site_sk,
      ws_net_paid,
      ws_quantity,
      ws_order_number
    FROM web_sales
  )
SELECT
  d.d_year,
  s.s_state,
  i_ws.i_brand,
  SUM(ssa.ss_net_paid)               AS store_sales_total,
  SUM(csag.cs_net_paid)               AS catalog_sales_total,
  SUM(wsa.ws_net_paid)                AS web_sales_total,
  SUM(sr.sr_net_loss)                 AS store_returns_loss,
  SUM(wr.wr_net_loss)                 AS web_returns_loss,
  COUNT(DISTINCT ssa.ss_ticket_number) AS store_orders,
  COUNT(DISTINCT wsa.ws_order_number)  AS web_orders
FROM date_dim d
RIGHT OUTER JOIN store_sales_agg ssa
  ON ssa.ss_sold_date_sk = d.d_date_sk
LEFT JOIN store s
  ON ssa.ss_store_sk = s.s_store_sk
LEFT JOIN time_dim t
  ON ssa.ss_sold_time_sk = t.t_time_sk
LEFT JOIN item i_ws
  ON ssa.ss_item_sk = i_ws.i_item_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ssa.ss_ticket_number
     AND sr.sr_item_sk = ssa.ss_item_sk
LEFT JOIN catalog_sales_agg csag
  ON csag.cs_sold_date_sk = d.d_date_sk
LEFT JOIN item i_cs
  ON csag.cs_item_sk = i_cs.i_item_sk
LEFT JOIN web_sales_agg wsa
  ON wsa.ws_sold_date_sk = d.d_date_sk
LEFT JOIN item i_w
  ON wsa.ws_item_sk = i_w.i_item_sk
LEFT JOIN web_page wp
  ON wsa.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site we
  ON wsa.ws_web_site_sk = we.web_site_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = wsa.ws_order_number
     AND wr.wr_item_sk = wsa.ws_item_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND i_ws.i_brand = 'Brand1'
  AND t.t_hour BETWEEN 9 AND 17
  AND csag.cs_quantity > 2
GROUP BY d.d_year, s.s_state, i_ws.i_brand
ORDER BY store_sales_total DESC
LIMIT 100
