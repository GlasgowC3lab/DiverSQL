WITH avg_return AS (
    SELECT AVG(cr_return_amount) AS avg_ret
    FROM catalog_returns
)
SELECT
    c.c_customer_id,
    ca.ca_state AS address_state,
    cc.cc_state AS call_center_state,
    sm.sm_carrier,
    w.w_warehouse_name,
    wp.wp_type,
    r.r_reason_desc,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_quantity) AS avg_quantity,
    CASE WHEN SUM(ws.ws_net_paid) > (SELECT avg_ret FROM avg_return) THEN 'HIGH' ELSE 'LOW' END AS revenue_category
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE
    ca.ca_zip = '98579' AND
    sm.sm_carrier = 'AIRBORNE' AND
    cc.cc_state = 'CA' AND
    wp.wp_type = 'content' AND
    ws.ws_sold_date_sk BETWEEN 2451910 AND 2451915 AND
    cr.cr_return_amount > 100
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    cc.cc_state,
    sm.sm_carrier,
    w.w_warehouse_name,
    wp.wp_type,
    r.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
