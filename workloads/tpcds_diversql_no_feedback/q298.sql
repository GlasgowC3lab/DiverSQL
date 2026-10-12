WITH ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_promo_sk,
        ws.ws_warehouse_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
)
SELECT
    w.w_state,
    p.p_promo_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(i.inv_quantity_on_hand) AS total_inventory
FROM ws_base ws
JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
LEFT JOIN tpcds.inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_city = 'Spring'
  AND ca.ca_suite_number = 'Suite B   '
  AND w.w_zip = '64593     '
  AND p.p_promo_name = 'Holiday Sale'
GROUP BY GROUPING SETS (
    (w.w_state, p.p_promo_name),
    (w.w_state),
    (p.p_promo_name),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
