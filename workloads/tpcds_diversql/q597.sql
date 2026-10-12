WITH filtered_items AS (
    SELECT i_item_sk, i_item_id, i_size, i_brand_id, i_current_price, i_color
    FROM tpcds.item
    WHERE i_size = 'medium'
      AND i_brand_id IN (6008007, 6012006)
),
inventory_sampled AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM tpcds.inventory TABLESAMPLE BERNOULLI (10)
    WHERE inv_quantity_on_hand < 100
)
SELECT
    cc.cc_name,
    w.w_state,
    i.i_color,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    COUNT(DISTINCT ca.ca_address_sk) AS distinct_customer_addresses,
    MIN(ws.ws_quantity) AS min_ws_quantity,
    MAX(cr.cr_return_quantity) AS max_return_quantity
FROM filtered_items i
JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN tpcds.customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN inventory_sampled inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_return_quantity > 5
  AND cr.cr_store_credit > 10
  AND ws.ws_quantity > 10
  AND ws.ws_net_paid > 100
  AND cc.cc_state = 'CA'
  AND w.w_state = 'TX'
  AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM tpcds.item i2)
GROUP BY cc.cc_name, w.w_state, i.i_color
HAVING SUM(cr.cr_return_amount) > 0
UNION DISTINCT
SELECT
    cc.cc_name,
    w.w_state,
    i.i_color,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    COUNT(DISTINCT ca.ca_address_sk) AS distinct_customer_addresses,
    MIN(ws.ws_quantity) AS min_ws_quantity,
    MAX(cr.cr_return_quantity) AS max_return_quantity
FROM filtered_items i
JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN tpcds.customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN inventory_sampled inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cd_refund.cd_gender = 'M'
  AND cd_refund.cd_purchase_estimate >= 6000
  AND r.r_reason_desc = 'Damaged'
  AND i.i_color = 'red'
  AND i.i_current_price BETWEEN 10 AND 100
  AND EXISTS (SELECT 1 FROM tpcds.reason r2 WHERE r2.r_reason_sk = r.r_reason_sk AND r2.r_reason_desc = r.r_reason_desc)
GROUP BY cc.cc_name, w.w_state, i.i_color
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
LIMIT 100
