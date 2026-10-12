SELECT
    w.w_warehouse_name,
    sm.sm_type AS ship_mode,
    cd.cd_education_status,
    cd.cd_marital_status,
    wp.wp_type AS page_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_qty,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS avg_discount_rate,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
FROM web_sales ws
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
  ON w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450906 AND 2451088
  AND ws.ws_ext_sales_price >= 500
  AND wp.wp_type = 'product'
GROUP BY
    w.w_warehouse_name,
    sm.sm_type,
    cd.cd_education_status,
    cd.cd_marital_status,
    wp.wp_type
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 50
