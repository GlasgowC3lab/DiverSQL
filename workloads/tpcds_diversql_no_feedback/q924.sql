WITH filtered_items AS (
  SELECT i_item_sk
  FROM item
  WHERE i_color = 'Red'
),
warehouse_filter AS (
  SELECT w_warehouse_sk
  FROM warehouse
  WHERE w_city = 'Springfield'
  INTERSECT
  SELECT w_warehouse_sk
  FROM warehouse
  WHERE w_state = 'CA'
)
SELECT
  w.w_warehouse_name,
  sm.sm_type,
  td.t_hour,
  site.web_name,
  SUM(ws.ws_net_profit) AS total_net_profit,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_quantity) AS avg_return_quantity,
  COUNT(DISTINCT ws.ws_order_number) AS order_count,
  SUM(inv.inv_quantity_on_hand) AS total_inventory,
  MIN(wr.wr_return_amt_inc_tax) AS min_return_inc_tax,
  MAX(wr.wr_return_amt_inc_tax) AS max_return_inc_tax
FROM catalog_returns cr
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer cust_refunded
  ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_time_sk = td.t_time_sk
 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
 AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_order_number = ws.ws_order_number
 AND wr.wr_web_page_sk = wp.wp_web_page_sk
 AND wr.wr_returned_time_sk = td.t_time_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_county = 'Walker County'
  AND w.w_street_number = '410'
  AND td.t_hour = 14
  AND sm.sm_type = 'AIR'
  AND site.web_state = 'CA'
  AND cd_refunded.cd_gender = 'F'
  AND cr.cr_return_amount > 500
  AND cr.cr_item_sk IN (SELECT i_item_sk FROM filtered_items)
  AND ws.ws_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse_filter)
GROUP BY w.w_warehouse_name, sm.sm_type, td.t_hour, site.web_name
ORDER BY total_net_profit DESC
LIMIT 100
