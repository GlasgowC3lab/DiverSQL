SELECT ws_web_site_sk,
       SUM(ws_net_profit) AS total_profit,
       COUNT(*)        AS order_cnt
FROM   tpcds.web_sales
WHERE  ws_ship_hdemo_sk IN (6843, 2307)
  AND  ws_web_site_sk = 39
GROUP BY ws_web_site_sk
