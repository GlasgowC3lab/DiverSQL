SELECT
    cs_call_center_sk,
    cs_ship_addr_sk,
    COUNT(*) AS order_cnt,
    SUM(cs_net_profit) AS total_profit
FROM tpcds.catalog_sales
WHERE cs_call_center_sk = 40
  AND cs_ship_addr_sk = 1128744
GROUP BY cs_call_center_sk, cs_ship_addr_sk
ORDER BY total_profit DESC
