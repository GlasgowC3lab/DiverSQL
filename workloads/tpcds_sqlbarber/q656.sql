SELECT
    ws.ws_web_site_sk,
    wsit.web_name,
    d.d_year,
    cc.cc_name,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
    (SELECT ws2.ws_quantity FROM web_sales ws2 WHERE ws2.ws_order_number = ws.ws_order_number) AS sample_quantity
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_year = 1928
GROUP BY ws.ws_web_site_sk, wsit.web_name, d.d_year, cc.cc_name, ws.ws_order_number
HAVING SUM(ws.ws_net_paid) > 2167.20
