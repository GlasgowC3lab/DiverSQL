WITH inventory_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    cc.cc_name,
    w.w_state,
    sm.sm_type,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(inventory_agg.total_qty_on_hand) AS warehouse_qty,
    ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) DESC) AS row_num
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   AND ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   AND ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   AND ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN inventory_agg
    ON w.w_warehouse_sk = inventory_agg.inv_warehouse_sk
WHERE cc.cc_employees > 1000000
  AND ca_bill.ca_state = 'CA'
  AND cs.cs_wholesale_cost > 30
  AND w.w_city = 'New York'
  AND sm.sm_type = 'AIR'
  AND ws.ws_quantity > 5
GROUP BY GROUPING SETS (
    (cc.cc_name, w.w_state),
    (sm.sm_type),
    ()
)
ORDER BY catalog_profit DESC
LIMIT 100
