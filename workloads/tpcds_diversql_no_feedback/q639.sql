WITH cs_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    cc.cc_name,
    d.d_date,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(wr.wr_return_quantity) AS total_returns,
    RANK() OVER (PARTITION BY cc.cc_division ORDER BY SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) DESC) AS division_profit_rank
FROM cs_sample cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh
  ON cs.cs_warehouse_sk = wh.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
 AND ws.ws_sold_time_sk = td.t_time_sk
 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
 AND ws.ws_warehouse_sk = wh.w_warehouse_sk
 AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_returned_date_sk = d.d_date_sk
 AND wr.wr_returned_time_sk = td.t_time_sk
WHERE
    d.d_year = 2001
    AND cp.cp_type = 'monthly'
    AND p.p_discount_active = 'Y'
    AND cc.cc_state = 'TX'
    AND sm.sm_type = 'AIR'
    AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    cc.cc_name,
    cc.cc_division,
    d.d_date
ORDER BY
    total_net_profit DESC
LIMIT 100
