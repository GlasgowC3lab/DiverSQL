WITH dim_vals AS (
    SELECT * FROM (VALUES (1, 'GroupA'), (2, 'GroupB')) AS t(grp, grp_name)
)
SELECT
    td.t_hour,
    s.s_state,
    w.w_county,
    ws.ws_web_site_sk,
    ws.ws_warehouse_sk,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid)               AS total_ws_net_paid,
    SUM(ss.ss_net_paid)               AS total_ss_net_paid,
    AVG(ws.ws_net_profit)             AS avg_ws_profit,
    MIN(td.t_time_sk)                 AS min_time_sk,
    ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rn,
    dv.grp,
    dv.grp_name
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim td
  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr
  ON wr.wr_returned_time_sk = td.t_time_sk
     AND wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
CROSS JOIN dim_vals dv
WHERE s.s_state = 'WA'
  AND w.w_county = 'Richland County'
  AND w.w_gmt_offset = -5.00
  AND td.t_hour BETWEEN 9 AND 17
  AND ws.ws_net_profit > 1000
GROUP BY
    td.t_hour,
    s.s_state,
    w.w_county,
    ws.ws_web_site_sk,
    ws.ws_warehouse_sk,
    dv.grp,
    dv.grp_name
ORDER BY rn
LIMIT 100
