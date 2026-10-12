WITH
  agg_ws AS (
    SELECT
      ws_order_number,
      SUM(ws_ext_sales_price) AS total_ext_sales_price,
      SUM(ws_net_paid)        AS total_net_paid
    FROM web_sales
    GROUP BY ws_order_number
  ),
  store_with_date AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      d.d_date AS store_closed_date
    FROM store s
    JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
  ),
  promo_agg AS (
    SELECT
      p_promo_sk,
      COUNT(*) AS promo_count
    FROM promotion
    GROUP BY p_promo_sk
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY agg_ws.total_net_paid DESC) AS row_num,
  cc.cc_name,
  cc.cc_state,
  d_ret.d_date               AS return_date,
  r.r_reason_desc,
  p.p_promo_name,
  swd.s_store_name,
  agg_ws.total_net_paid,
  SUM(cr.cr_return_amount)   AS total_return_amount,
  (
    SELECT SUM(cr2.cr_return_amount)
    FROM catalog_returns cr2
    WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
  )                           AS total_returns_for_cc,
  pa.promo_count
FROM catalog_returns cr
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
-- bring in web_sales (cross join then filter via date_dim joins)
JOIN web_sales ws
  ON 1 = 1
JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN agg_ws agg_ws
  ON ws.ws_order_number = agg_ws.ws_order_number
JOIN promo_agg pa
  ON p.p_promo_sk = pa.p_promo_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store_with_date swd
  ON 1 = 1
WHERE d_ret.d_year = 2001
  AND p.p_channel_event = 'N'
GROUP BY
  cc.cc_name,
  cc.cc_state,
  d_ret.d_date,
  r.r_reason_desc,
  p.p_promo_name,
  swd.s_store_name,
  agg_ws.total_net_paid,
  pa.promo_count,
  cc.cc_call_center_sk
ORDER BY agg_ws.total_net_paid DESC
LIMIT 100
