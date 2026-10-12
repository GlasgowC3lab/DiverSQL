WITH
  order_excl_returns AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    EXCEPT
    SELECT wr.wr_order_number
    FROM web_returns wr
  ),
  intersect_ticket_order AS (
    SELECT sr.sr_ticket_number
    FROM store_returns sr
    INTERSECT
    SELECT wr.wr_order_number
    FROM web_returns wr
  )
SELECT
  st.s_store_name,
  dr.d_year,
  COUNT(DISTINCT ws.ws_order_number) AS num_orders,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(sr.sr_return_amt) AS total_store_returns,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  MIN(ws.ws_net_profit) AS min_profit,
  MAX(ws.ws_net_profit) AS max_profit
FROM store_returns sr
FULL OUTER JOIN store st
  ON sr.sr_store_sk = st.s_store_sk
LEFT JOIN date_dim dr
  ON sr.sr_returned_date_sk = dr.d_date_sk
LEFT JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
  ON ws.ws_sold_date_sk = dr.d_date_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN warehouse wh
  ON ws.ws_warehouse_sk = wh.w_warehouse_sk
LEFT JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
WHERE dr.d_year = 2001
  AND ca.ca_state = 'CA'
  AND wh.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND r.r_reason_desc LIKE '%missing%'
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = ws.ws_promo_sk
          AND p2.p_discount_active = 'Y'
      )
  AND ws.ws_order_number IN (SELECT ws_order_number FROM order_excl_returns)
  AND sr.sr_ticket_number IN (SELECT sr_ticket_number FROM intersect_ticket_order)
GROUP BY st.s_store_name, dr.d_year
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
