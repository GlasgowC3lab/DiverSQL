SELECT
    cc.cc_division_name,
    s.s_state,
    d_closed.d_year AS closed_year,
    d_open.d_year AS open_year,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_count,
    COUNT(DISTINCT s.s_store_sk) AS store_count,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) AS net_contribution,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    SUM(CASE WHEN ws.ws_sales_price > ws.ws_wholesale_cost THEN 1 ELSE 0 END) AS high_margin_sales_count
FROM call_center cc
JOIN date_dim d_closed
  ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
  ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d_closed.d_date_sk
  AND sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_closed.d_date_sk
  AND ws.ws_ship_date_sk = d_closed.d_date_sk
GROUP BY
    cc.cc_division_name,
    s.s_state,
    d_closed.d_year,
    d_open.d_year
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY net_contribution DESC
LIMIT 100
