WITH joined AS (
  SELECT
    d.d_year,
    s.s_state,
    sm.sm_type,
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    sr.sr_return_amt,
    r.r_reason_id,
    r.r_reason_desc,
    wsite.web_country,
    wp.wp_type
  FROM date_dim d
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
  LEFT JOIN customer_address ca_sr_addr ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
  LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
  LEFT JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
  LEFT JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
  LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
  LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
)
SELECT
  d_year,
  s_state,
  sm_type,
  SUM(ws_net_profit) AS total_profit,
  COUNT(DISTINCT ws_order_number) AS distinct_orders,
  SUM(DISTINCT sr_return_amt) AS total_return_amount,
  COUNT(DISTINCT r_reason_id) AS distinct_reason_ids
FROM joined
WHERE d_year = 2001
  AND ws_net_profit > 0
  AND s_state = 'TX'
  AND r_reason_desc LIKE '%Customer%'
  AND web_country = 'United States'
GROUP BY d_year, s_state, sm_type
ORDER BY total_profit DESC
LIMIT 100
