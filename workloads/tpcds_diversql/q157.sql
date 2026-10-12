WITH max_price AS (
    SELECT MAX(i_current_price) AS max_price
    FROM item
    WHERE i_brand = 'BrandX'
)
SELECT
    wsite.web_name,
    sm.sm_carrier,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    MIN(ws.ws_ext_tax) AS min_tax,
    MAX(ws.ws_ext_tax) AS max_tax,
    SUM(CASE WHEN ws.ws_net_paid > 10000 THEN 1 ELSE 0 END) AS high_value_orders
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_customer_sk = c.c_customer_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = wh.w_warehouse_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    sm.sm_carrier = 'MSC'
    AND wsite.web_class = 'Unknown'
    AND inv.inv_quantity_on_hand > 0
    AND ib.ib_lower_bound >= 30000
    AND ws.ws_ext_list_price > 1000
    AND i.i_current_price > (SELECT max_price FROM max_price)
GROUP BY ROLLUP (wsite.web_name, sm.sm_carrier)
ORDER BY total_net_paid DESC
LIMIT 100
