WITH cs AS (
  SELECT
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid_inc_ship_tax,
    cs.cs_net_profit,
    ca.ca_city,
    td.t_second,
    cp.cp_department,
    p.p_discount_active,
    sm.sm_type,
    w.w_warehouse_name
  FROM catalog_sales cs
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE cs.cs_net_paid_inc_ship_tax > 2000
    AND cs.cs_net_profit < 0
    AND ca.ca_city = 'Spring'
    AND td.t_second IN (7, 11)
    AND p.p_discount_active = 'Y'
),
ws AS (
  SELECT
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ca.ca_city AS ws_city,
    td.t_second AS ws_second,
    sm.sm_type AS ws_ship_type,
    w.w_warehouse_name AS ws_warehouse,
    we.web_state
  FROM web_sales ws
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE ws.ws_quantity >= 10
    AND ws.ws_net_profit > 100
    AND we.web_state = 'CA'
    AND td.t_second NOT IN (3, 9)
    AND sm.sm_type = 'AIR'
)
SELECT
  COALESCE(cs.cs_order_number, ws.ws_order_number) AS order_number,
  COUNT(DISTINCT COALESCE(cs.cs_order_number, ws.ws_order_number)) AS distinct_orders,
  SUM(COALESCE(cs.cs_net_paid_inc_ship_tax, 0)) AS total_cs_net_paid_inc_ship_tax,
  AVG(COALESCE(cs.cs_net_profit, 0)) AS avg_cs_net_profit,
  SUM(COALESCE(ws.ws_net_paid, 0)) AS total_ws_net_paid,
  AVG(COALESCE(ws.ws_net_profit, 0)) AS avg_ws_net_profit,
  MIN(COALESCE(cs.cs_quantity, ws.ws_quantity)) AS min_quantity,
  MAX(COALESCE(cs.cs_quantity, ws.ws_quantity)) AS max_quantity,
  MIN(cs.ca_city) AS cs_city,
  MIN(ws.ws_city) AS ws_city
FROM cs
FULL OUTER JOIN ws ON TRUE
GROUP BY COALESCE(cs.cs_order_number, ws.ws_order_number)
ORDER BY total_cs_net_paid_inc_ship_tax DESC
LIMIT 100
