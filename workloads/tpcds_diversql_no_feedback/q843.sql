WITH order_diff AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT sr.sr_ticket_number
    FROM store_returns sr
)
SELECT
    t.t_hour,
    cc.cc_name,
    cp.cp_department,
    s.s_store_name,
    we.web_name,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number)            AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number)           AS store_tickets,
    COUNT(DISTINCT ws.ws_order_number)            AS web_orders,
    SUM(cs.cs_net_profit)                         AS total_catalog_profit,
    SUM(ss.ss_net_profit)                         AS total_store_profit,
    SUM(ws.ws_net_profit)                         AS total_web_profit,
    MIN(t.t_hour)                                 AS min_hour,
    MAX(t.t_hour)                                 AS max_hour
FROM catalog_sales cs
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_returned_time_sk = t.t_time_sk
JOIN store_sales ss
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_return_time_sk = t.t_time_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = t.t_time_sk
 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN order_diff od
  ON cs.cs_order_number = od.cs_order_number
WHERE
    t.t_hour BETWEEN 9 AND 17                                 -- predicate 1 (time of day)
AND cc.cc_state = 'CA'                                         -- predicate 2 (call center state)
AND cp.cp_department = 'Electronics'                          -- predicate 3 (catalog department)
AND s.s_state = 'TX'                                           -- predicate 4 (store state)
AND we.web_state = 'CA'                                        -- predicate 5 (web site state)
AND sm.sm_type = 'AIR'                                         -- predicate 6 (ship mode type)
AND cs.cs_order_number NOT IN (
        SELECT cr2.cr_order_number
        FROM catalog_returns cr2
        WHERE cr2.cr_return_amount > 5000
    )
GROUP BY
    t.t_hour,
    cc.cc_name,
    cp.cp_department,
    s.s_store_name,
    we.web_name,
    sm.sm_type
ORDER BY
    total_catalog_profit DESC
LIMIT 100
