SELECT
    ws.ws_sold_date_sk AS sale_date_sk,
    wp.wp_type AS page_type,
    wp.wp_url,
    COUNT(*) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(
        (SELECT AVG(inv_quantity_on_hand)
         FROM inventory inv
         WHERE inv.inv_item_sk = ws.ws_item_sk
           AND inv.inv_date_sk = ws.ws_sold_date_sk)
    ) AS avg_inventory_on_hand,
    (SELECT cc_manager
     FROM call_center cc
     WHERE cc.cc_state = 'CA'
     ORDER BY cc.cc_closed_date_sk DESC
     LIMIT 1) AS ca_manager
FROM web_sales ws
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_net_profit > 0
  AND wp.wp_type IN ('Content', 'Product')
  AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY
    ws.ws_sold_date_sk,
    wp.wp_type,
    wp.wp_url
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 10
